# frozen_string_literal: true

require "active_function"

require "./src/clients/notion"
require "./src/clients/telegram"

class BudgetBot < ActiveFunction::Base
  before_action :set_message
  after_action :log_response

  PERMITTED_PARAMS = [
    :message_id,
    :text,
    chat: [
      :id,
      :first_name,
      :username,
      :type
    ]
  ].freeze

  MSG_REGEXP = /^((\s?)(\w+|[А-Яа-я]))* \d+ \w+$/

  def add_expense
    authorize! @message[:chat]

    expense_options = parse_expense(@message[:text])

    notion_client.create_page(**expense_options)

    if notion_client.request_succeed?
      telegram_client.send_message(text: "Expense added", chat_id: @message[:chat][:id])

      render status: 200
    else
      render json: { errors: notion_client.request_errors }, status: 500
    end
  end

  private

  def parse_expense(text)
    {
      expense:  text[0..text.index(/\s\d/)].strip,
      amount:   text[text.index(/\s\d/)..text.index(/\d\s/)].to_i,
      category: text[(text.index(/\d\s/) + 1)..].strip.capitalize
    }
  end

  def set_message
    raise ArgumentError, "Wrong Telegram Event Type" unless params[:message][:text]
    raise ArgumentError, "Wrong Telegram Message Format" unless params[:message][:text] in MSG_REGEXP

    @message = params
      .require(:message)
      .permit(*PERMITTED_PARAMS)
      .to_h
  end

  def log_response
    Application.log "Response: #{@response.to_h}"
  end

  def authorize!(msg)
    authorized_users = ENV.fetch("AUTHORIZED_USERS").split(",")

    raise "Unauthorized" unless authorized_users.include? msg[:id].to_s
  end

  def notion_client
    @notion_client ||= Clients::Notion.new
  end

  def telegram_client
    @telegram_client ||= Clients::Telegram.new
  end
end
