# frozen_string_literal: true

require "logger"
require "./src/functions/expenses_function"

$logger = Logger.new($stdout)

class Application
  def self.process(event:, context:)
    raise "Invalid Webhook Event" unless event["headers"]["X-Telegram-Bot-Api-Secret-Token"] == ENV.fetch("TELEGRAM_WEBHOOK_TOKEN")

    msg = JSON.parse(event["body"], symbolize_names: true)

    log "Telegram Event Received: #{msg}"

    ExpensesFunction.process(:add, message: msg.fetch(:message))
  rescue => e
    log "Error: #{e.full_message}}", level: :error
  end

  def self.log(message, level: :info)
    $logger.send(level, message)
  end
end
