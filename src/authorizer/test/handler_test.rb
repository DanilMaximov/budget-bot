# frozen_string_literal: true

require "test_helper"
require_relative "../handler"

class HandlerTest < Minitest::Test
  def setup
    setup_common_stubs
    setup_logger_mock
  end

  def setup_common_stubs
    @event   = {
      "body"    => JSON.generate({ message: { chat: { id: 123 } } }),
      "headers" => {
        "X-Telegram-Bot-Api-Secret-Token" => "token-abc"
      }
    }
    @context = {}

    Authorizer.any_instance.stubs(:authorized_users).returns([ "123", "456" ])
    Authorizer.any_instance.stubs(:webhook_token).returns("token-abc")
  end

  def setup_logger_mock
    @logger_mock = mock("Logger")
    Authorizer.any_instance.stubs(:logger).returns(@logger_mock)
  end

  def test_handler_with_authorized_user
    @logger_mock.stubs(:info)

    response = Authorizer.handler(event: @event, context: @context)

    assert_equal "user", response[:principalId]
    assert_equal "Allow", response[:policyDocument][:Statement][0][:Effect]
    assert_equal @event["methodArn"], response[:policyDocument][:Statement][0][:Resource]
  end

  def test_handler_with_unauthorized_user
    @logger_mock.stubs(:error)

    Authorizer.any_instance.stubs(:authorized_users).returns([ "456" ])

    response = Authorizer.handler(event: @event, context: @context)

    assert_equal "Deny", response[:policyDocument][:Statement][0][:Effect]
  end

  def test_wrong_webhook_url
    @logger_mock.stubs(:error)

    Authorizer.any_instance.stubs(:webhook_token).returns("wrong-token")

    response = Authorizer.handler(event: @event, context: @context)

    assert_equal "Deny", response[:policyDocument][:Statement][0][:Effect]
  end

  def test_wrong_telegram_event
    @logger_mock.stubs(:error)

    @event["body"] = { message: { chat: { no_id: nil } } }.to_json

    response = Authorizer.handler(event: @event, context: @context)

    assert_equal "Deny", response[:policyDocument][:Statement][0][:Effect]
  end
end
