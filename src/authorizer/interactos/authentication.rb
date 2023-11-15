# frozen_string_literal: true

require_relative "interactor"
require_relative "../helpers/types"

TELEGRAM_WEBHOOK_TOKEN = ENV.fetch("TELEGRAM_WEBHOOK_TOKEN")

Authentication = Interactor.define(:aws_event, :body, :headers) do
  TelegramRequestValidator = Struct.new(:payload, :headers) do
    COMMAND_REGEXP = /\w+/

    InvalidWebhookEventError  = Class.new(StandardError)
    InvalidTelegramEventError = Class.new(StandardError)

    def validate!
      validate_webhook_token!
      validate_telegram_event!
    end

    private

    def validate_webhook_token!
      headers["X-Telegram-Bot-Api-Secret-Token"] == TELEGRAM_WEBHOOK_TOKEN ||
        raise(InvalidWebhookEventError)
    end

    def validate_telegram_event!
      (Types::Event::Chat::EType.to_a & payload.except(:update_id).keys).any? ||
        raise(InvalidTelegramEventError)
    end
  end

  WebApiRequestValidator = Struct.new(:payload, :headers) do
    def validate!
    end
  end

  InvalidRequestTypeError = Class.new(StandardError)

  REQUEST_TYPES = {
    "/tg_webhook" => Types::Event::EType.telegram,
    "/api"        => Types::Event::EType.web_api
  }

  VALIDATORS = {
    Types::Event::EType.telegram => TelegramRequestValidator,
    Types::Event::EType.web_api  => WebApiRequestValidator
  }

  def call
    set_request_type
    validate_event!
  end

  def request_type = context.request_type

  private

  def validator = VALIDATORS[request_type][body, headers]

  def set_request_type
    request_path = aws_event["path"]

    context.request_type = REQUEST_TYPES[request_path] || raise(InvalidRequestTypeError)
  end

  def validate_event!
    validator.validate!
  end
end
