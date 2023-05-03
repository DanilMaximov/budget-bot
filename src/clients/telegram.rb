# frozen_string_literal: true

require_relative "base_client"

module Clients
  class Telegram < BaseClient
    BASE_URL = "https://api.telegram.org/bot"

    def send_message(chat_id:, text:)
      params = { chat_id: chat_id, text: text }

      make_request("sendMessage", params: params, method: :get)
    end

    private

    def base_url = BASE_URL + ENV.fetch("TELEGRAM_TOKEN")
  end
end
