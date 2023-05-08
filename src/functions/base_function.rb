# frozen_string_literal: true

require "active_function"
require_relative "../clients/telegram"

class Base < ActiveFunction::Base
  PERMITTED_PARAMS = [
    :message_id,
    :text,
    chat: %i[id first_name username type]
  ].freeze

  before_action :set_message
  after_action :log_response

  def render(json:, **)
    super

    return unless json[:text]

    telegram_client.send_message(
      chat_id: json[:chat_id] || @message[:chat][:id],
      text:    json[:text]
    )
  end

  private

  def authorize!(msg)
    authorized_users = ENV.fetch("AUTHORIZED_USERS").split(",")

    raise "Unauthorized" unless authorized_users.include? msg[:id].to_s
  end

  def set_message
    raise ArgumentError, "Wrong Telegram Event Type" unless params[:message][:text]

    @message = params
      .require(:message)
      .permit(*PERMITTED_PARAMS)
      .to_h
  end

  def log_response
    Application.log "Response: #{@response.to_h}"
  end

  def telegram_client
    @telegram_client ||= Clients::Telegram.new
  end
end
