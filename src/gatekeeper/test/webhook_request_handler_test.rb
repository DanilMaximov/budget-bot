# frozen_string_literal: true

require "test_helper"
require_relative "support/requests_helper"

require_relative "../webhook_request_handler"
require_relative "../models/account"

describe WebHookRequestHandler do
  let(:described_class) { WebHookRequestHandler }

  let(:request) { webhook_request.text }
  let(:webhook_event_body) { request.to_json }
  let(:webhook_update) { TelegramUpdate.build_from_webhook_request(request) }

  let(:aws_event) { aws_request.event.merge("body" => webhook_event_body) }

  let(:account_session) { Account::Session.new(id: 1, internal_id: 1, account_id: 1, last_event_id: 1, status: :free) }
  let(:ddb_response) { { items: [ account_session.to_h.transform_keys(&:to_s) ] } }

  before do
    dynamodb = Aws::DynamoDB::Client.new(stub_responses: true)
    dynamodb.stub_responses(:execute_statement, ddb_response)

    time = Time.now
    Time.stubs(:now).returns(time)

    ::DDB = dynamodb # stub :////
  end

  describe "::handle" do
    let(:event) { described_class::Event.new(action: :default, payload: webhook_update.to_h) }

    describe "EventBridge event enqueue" do
      let(:expected_event) do
        {
          detail:         event.to_h.to_json,
          detail_type:    :default,
          event_bus_name: :webhook_event_handler,
          time:           Time.now
        }
      end

      before do
        described_class.send(:event_bridge).expects(:put_events).with(entries: [ expected_event ])
      end

      describe "when session exists" do
        it "handles a valid update event" do
          described_class.handle(event: aws_event, context: {})
        end
      end

      describe "when session does not exist" do
        let(:event) { described_class::Event.new(action: :new_session, payload: webhook_update.to_h) }
        let(:expected_event) do
          {
            detail:         event.to_h.to_json,
            detail_type:    :new_session,
            event_bus_name: :webhook_event_handler,
            time:           Time.now
          }
        end

        let(:ddb_response) { { items: [] } }

        it "handles a valid update event" do
          described_class.handle(event: aws_event, context: {})
        end
      end
    end

    describe "Lambda response" do
      let(:delete_response) do
        {
          statusCode: 200,
          headers:    { "Content-Type": "application/json" },
          body:       {
            method:     "deleteMessage",
            chat_id:    webhook_update.chat.id,
            message_id: webhook_update.message.message_id
          }.to_json
        }
      end

      let(:default_response) do
        {
          statusCode: 200,
          body:       "OK",
          headers:    { "Content-Type": "application/text" }
        }
      end

      describe "when webhook update is a message from user" do
        let(:request) { webhook_request.command }

        it "return delete message response" do
          described_class.handle(event: aws_event, context: {}).tap do |response|
            assert_equal delete_response, response
          end
        end

        describe "when unexpected error occurs" do
          before do
            described_class.any_instance.stubs(:enqueue).raises(StandardError)
          end

          it "returns delete message response" do
            described_class.handle(event: aws_event, context: {}).tap do |response|
              assert_equal delete_response, response
            end
          end
        end
      end

      describe "when webhook update is a callback query" do
        let(:request) { webhook_request.callback_query }

        it "return default response" do
          described_class.handle(event: aws_event, context: {}).tap do |response|
            assert_equal default_response, response
          end
        end
      end
    end

    describe "Authentication" do
      describe "when session is busy" do
        let(:account_session) { Account::Session.new(id: 1, internal_id: 1, account_id: 1, last_event_id: 1, status: :busy) }

        before do
          described_class.send(:event_bridge).expects(:put_events).never
        end

        it "doesn't enqueue event" do
          described_class.handle(event: aws_event, context: {})
        end
      end

      describe "when already processed event appeared" do
        let(:account_session) { Account::Session.new(id: 1, internal_id: 1, account_id: 1, last_event_id: webhook_update.update_id, status: :free) }

        before do
          described_class.send(:event_bridge).expects(:put_events).never
        end

        it "doesn't enqueue event" do
          described_class.handle(event: aws_event, context: {})
        end
      end

      describe "when session doesnt exist" do
        let(:ddb_response) { { items: [] } }

        before do
          Account::Session.expects(:create).once
        end

        it " a new session record" do
          described_class.handle(event: aws_event, context: {})

          # subject
        end
      end
    end
  end
end
