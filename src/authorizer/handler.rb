# frozen_string_literal: true

# authorizer.rb

require "json"
require "logger"

LOGGER                 = Logger.new($stdout)
TELEGRAM_WEBHOOK_TOKEN = ENV.fetch("TELEGRAM_WEBHOOK_TOKEN")
AUTHORIZED_USERS       = ENV.fetch("AUTHORIZED_USERS").split(",")

class Authorizer
  Error = Class.new(StandardError)

  InvalidWebhookEventError = Class.new(Error) do
    def full_message = "Invalid Webhook Event"
  end

  UnauthorizedError = Class.new(Error) do
    def full_message = "Unauthorized"
  end

  InvalidTelegramEventError = Class.new(Error) do
    def full_message = "Invalid Telegram Event"
  end

  def self.handler(event:, context:)
    new(event, context).call
  end

  def initialize(event, context)
    @event   = event
    @context = context
  end

  def call
    authorize!
    allow_access
  rescue => e
    deny_access(e.full_message)
  end

  private

  def authentication = @_authentication ||= Authentication[@request] # delegates request.body, request.headers
  def authenticate!
    authentication.execute

    raise AuthenticationError, authentication.errors unless authentication.success

    @request.type = authentication.request_type
  end

  def authorize!
    raise InvalidWebhookEventError unless @event["headers"]["X-Telegram-Bot-Api-Secret-Token"] == webhook_token

    msg = JSON.parse(@event["body"], symbolize_names: true)

    raise InvalidTelegramEventError unless msg in { message: { chat: {id: Integer} } }

    raise UnauthorizedError unless authorized_users.include?(msg[:message][:chat][:id].to_s)
  end

  def allow_access
    log_info("Access allowed")

    {
      principalId:    "user",
      policyDocument: {
        Version:   "2012-10-17",
        Statement: [
          {
            Action:   "execute-api:Invoke",
            Effect:   "Allow",
            Resource: @event["methodArn"]
          }
        ]
      }
    }
  end

  def deny_access(error_message)
    log_error("Authorization Error: #{error_message}")

    {
      principalId:    "user",
      policyDocument: {
        Version:   "2012-10-17",
        Statement: [
          {
            Action:   "execute-api:Invoke",
            Effect:   "Deny",
            Resource: @event["methodArn"]
          }
        ]
      }
    }
  end

  def log_info(message)
    logger.info(message)
  end
  
  def log_error(message)
    logger.error(message)
  end
end
