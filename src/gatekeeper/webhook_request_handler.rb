# frozen_string_literal: true

require_relative "models/telegram_update"
require_relative "models/account"
require "logger"

require "aws-sdk-dynamodb"
require "aws-sdk-eventbridge"

LOGGER = Logger.new($stdout)
DDB    = Aws::DynamoDB::Client.new
EB     = Aws::EventBridge::Client.new

class WebHookRequestHandler
  Event = Data.define(:action, :payload)

  Error             = Class.new(StandardError)
  ResponseReady     = Class.new(Error)
  IgnoreUpdateEvent = Class.new(ResponseReady) do
    MESSAGE_TEMPLATE = "Ignoring event id %{update_id} from %{chat_id} with %{name}>"

    def initialize(event)
      super format(MESSAGE_TEMPLATE, update_id: event.update_id, chat_id: event.chat.id, name: self.class.name)
    end
  end

  InvalidUpdateSequenceNumber = Class.new(IgnoreUpdateEvent)
  ClientBusy                  = Class.new(IgnoreUpdateEvent)

  class << self
    def handle(event:, context:)
      request_payload = JSON.parse(event["body"], symbolize_names: true)
      update          = TelegramUpdate.build_from_webhook_request(request_payload)

      authenticate!(update)

      enqueue_default_update_event(update)
    rescue ResponseReady => e
      logger.info("Response ready: #{e.message}")
    rescue => e
      logger.error(e.full_message)
    ensure
      return response(update) # rubocop:disable Lint/EnsureReturn
    end

    private

    def logger       = LOGGER
    def event_bridge = EB

    def authenticate!(update)
      raise InvalidUpdateChatType unless update.chat.type == "private"

      session = Account::Session.find_by(internal_id: update.chat.id, source: :telegram)

      setup_new_session!(update) if session.nil?

      raise InvalidUpdateSequenceNumber, update if update.update_id <= session.last_event_id
      raise ClientBusy, update if session.busy?

      session.update(last_event_id: update.update_id, status: :busy)
    end

    def setup_new_session!(update)
      Account::Session.create(
        internal_id:   update.chat.id,
        last_event_id: update.update_id,
        source:        :telegram,
        status:        :busy
      )

      enqueu_new_session_setup(update)
    end

    def enqueu_new_session_setup(update)
      enqueue Event[:new_session, update.to_h]
    end

    def enqueue_default_update_event(update)
      enqueue Event[:default, update.to_h]
    end

    def enqueue(event)
      event_bridge.put_events(
        entries: [ {
          detail:         event.to_h.to_json,
          detail_type:    event.action,
          event_bus_name: :webhook_event_handler,
          time:           Time.now
        } ]
      )

      raise ResponseReady
    end

    def response(update)
      if update.type == :message
        delete_user_input_response(update.chat.id, update.message.message_id)
      else
        default_response
      end
    end

    def delete_user_input_response(chat_id, message_id)
      {
        statusCode: 200,
        headers:    { "Content-Type": "application/json" },
        body:       { method: "deleteMessage", chat_id:, message_id: }.to_json
      }
    end

    def default_response
      {
        statusCode: 200,
        body:       "OK",
        headers:    { "Content-Type": "application/text" }
      }
    end
  end
end
