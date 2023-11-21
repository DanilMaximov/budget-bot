# frozen_string_literal: true

Event = Data.define(:action, :account_id, :payload)

class WebHookRequestHandler
  ResponseReady     = Class.new(StandardError)
  IgnoreUpdateEvent = Class.new(ResponseReady) do
    MESSAGE_TEMPLATE = "Ignoring event id %<update_id> from %<chat_id> with %<name>"

    def initialize(event)
      raise ArgumentError, "Invalid event: #{event}" unless event.is_a?(UpdateEvent)

      super(MESSAGE_TEMPLATE % { update_id: event.id, chat_id: event.chat.id, name: self.class.name })
    end
  end

  InvalidUpdateSequenceNumber = Class.new(IgnoreUpdateEvent)
  ClientBusy                  = Class.new(IgnoreUpdateEvent)

  Event = Data.define(:action, :account_id, :payload)

  class << self
    def handle(event:, context:)
      parsed_body = JSON.parse(event["body"], symbolize_names: true)
      update      = TelegramUpdate.build_from_webhook_request(request_payload)

      authenticate!(update)

      enqueue_default_update_event(update)
    rescue ResponseReady => e
      logger.info("Response ready: #{e.message}")
    rescue => e
      logger.error(e.full_message)
    ensure
      response
    end

    private

    def authenticate!(update)
      raise InvalidUpdateChatType unless update.chat.type == "private"

      integration = Account::Integeration.find_by(internal_id: update.chat.id)

      setup_new_user(update) if integration.nil?

      raise InvalidUpdateSequenceNumber, update if update.id <= integration.last_event_id
      raise ClientBusy, integration if integration.busy?

      user.update(last_event_id: update.id, status: :busy)
    end

    def setup_new_user(update)
      Account::Integeration.create(
        internal_id: update.chat.id,
        name: update.chat.username,
        last_event_id: update.id,
        status: :busy
      )

      integration = Account::Integeration.find_by!(internal_id: update.chat.id)

      enqueu_new_user_setup(update, integration)
    end

    def enqueu_new_user_setup(update, integration)
      enqueue Event[:new_user, integration.id, update.to_h], queue_name: :telegram_response_handler

      raise ResponseReady
    end

    def enqueue_default_update_event(update)
      enqueue Event[:default, integration.id, update.to_h]
    end

    def enqueue(event, queue_name: :telegram_event_handler)
      EventBridgeClient.throw_event(queue_name, data: event.to_h.to_json)
    end

    def response
      if update.type == :message
        delete_user_input_response(update.chat.id, update.message.message_id)
      else
        default_response
      end
    end

    def delete_user_input_response(chat_id, message_id)
      {
        statusCode: 200,
        headers: { "Content-Type": "application/json" },
        body: { method: "deleteMessage", chat_id: chat_id, message_id: message_id }.to_jsnon
      }
    end

    def default_response
      {
        statusCode: 200,
        body: "OK",
        headers: { "Content-Type": "application/text" }
      }
    end
  end
end
