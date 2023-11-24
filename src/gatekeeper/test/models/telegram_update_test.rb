# frozen_string_literal: true

require "test_helper"
require_relative "../../models/telegram_update"

describe TelegramUpdate do
  describe "::build_from_webhook_request" do
    let(:events_json) { File.read(File.expand_path("../fixtures/telegram_updates.json", __dir__)) }
    let(:requests) { JSON.parse(events_json, symbolize_names: true) }

    it "should build a TelegramUpdate from a text message" do
      request     = requests[:text]
      req_chat    = request[:message][:chat]
      req_message = request[:message]

      TelegramUpdate.build_from_webhook_request(request).tap do |update|
        assert_equal request[:update_id], update.update_id
        assert_equal req_message[:text], update.data
        assert_equal :command, update.type

        assert_equal req_message[:message_id], update.message.message_id
        assert_equal req_message[:date], update.message.date

        assert_equal req_chat[:id], update.chat.id
        assert_equal req_chat[:username], update.chat.username
        assert_equal req_chat[:first_name], update.chat.first_name
        assert_equal req_chat[:type], update.chat.type
      end
    end

    it "should build a TelegramUpdate from a callback query" do
      request     = requests[:callback_query]
      req_chat    = request[:callback_query][:message][:chat]
      req_message = request[:callback_query][:message]

      TelegramUpdate.build_from_webhook_request(request).tap do |update|
        assert_equal request[:update_id], update.update_id
        assert_equal request[:callback_query][:data], update.data
        assert_equal :callback_query, update.type

        assert_equal req_message[:message_id], update.message.message_id
        assert_equal req_message[:date], update.message.date

        assert_equal req_chat[:id], update.chat.id
        assert_equal req_chat[:username], update.chat.username
        assert_equal req_chat[:first_name], update.chat.first_name
        assert_equal req_chat[:type], update.chat.type
      end
    end

    it "should raise an error if the request is invalid" do
      assert_raises(TelegramUpdate::BuildError) do
        TelegramUpdate.build_from_webhook_request({})
      end
    end
  end
end
