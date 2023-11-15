# frozen_string_literal: true

require "test_helper"
require_relative "../../interactos/authentication"

describe Authentication do
  let(:data) { Data.define(:aws_event, :body, :headers) }
  let(:options) { { aws_event: {}, body: {}, headers: {} } }
  let(:context) { data.new(**options) }
  let(:interactor) { Authentication[context] }

  describe "unknown request type" do
    it "raises an error" do
      options[:aws_event]["path"] = "/invalid_path"

      interactor.execute

      _(interactor.errors.size).must_equal 1
      _(interactor.errors.first.class).must_equal InvalidRequestTypeError
    end
  end

  describe "validates a Telegram webhook request" do
    let(:options) {
      {
        aws_event: { "path" => "/tg_webhook" },
        body:      { update_id: 1, message: { chat: { id: 123 } } },
        headers:   { "X-Telegram-Bot-Api-Secret-Token" => ENV.fetch("TELEGRAM_WEBHOOK_TOKEN") }
      }
    }

    it "authenticates a valid request" do
      interactor.execute

      _(interactor.success).must_equal true
      _(interactor.errors).must_be_empty
      _(interactor.request_type).must_equal Types::Event::EType.telegram
    end

    it "fails to authenticate a request with invalid token" do
      options[:headers]["X-Telegram-Bot-Api-Secret-Token"] = "invalid-token"

      interactor.execute

      _(interactor.success).must_equal false
      _(interactor.errors.size).must_equal 1
      _(interactor.errors.first.class).must_equal InvalidWebhookEventError
    end

    it "fails to authenticate a request with invalid event" do
      options[:body].delete(:message)
      options[:body][:channel_post] = {}

      interactor.execute

      _(interactor.success).must_equal false
      _(interactor.errors.size).must_equal 1
      _(interactor.errors.first.class).must_equal InvalidTelegramEventError
    end
  end

  describe "validates a Web API request" do
    let(:options) {
      {
        aws_event: { "path" => "/api" },
        body:      { some_key: "some_value" },
        headers:   { "Authorization" => "Bearer valid_token" }
      }
    }

    it "validates a Web API request" do
      interactor.call

      _(interactor.success).must_equal true
      _(interactor.errors).must_be_empty
      _(interactor.request_type).must_equal Types::Event::EType.web_api
    end
  end
end
