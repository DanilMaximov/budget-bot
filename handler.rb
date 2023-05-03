# frozen_string_literal: true

require "./src/budget_bot"

def handler(event:, context:)
  raise "Invalid Webhook Event" unless event["headers"]["X-Telegram-Bot-Api-Secret-Token"] == ENV.fetch("TELEGRAM_WEBHOOK_TOKEN")

  msg = JSON.parse(event["body"], symbolize_names: true)

  p "<#{DateTime.now}> Request Received: #{msg}" # TODO: Introduce Logger

  BudgetBot.process(:add_expense, message: msg[:message])
end
