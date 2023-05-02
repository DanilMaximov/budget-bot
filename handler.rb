# frozen_string_literal: true

require "./src/budget_bot"

def handler(event, context)
  msg = JSON.parse(event["body"], symbolize_names: true).fetch(:message)

  BudgetBot.process(:add_expense, message: msg)
rescue => e
  {
    statusCode: 500,
    body:       e.detailed_message,
    headers:    { "Content-Type" => "application/json" }
  }
end
