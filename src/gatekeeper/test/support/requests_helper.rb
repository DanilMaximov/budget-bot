# frozen_string_literal: true

module RequestsHelper
  module AwsRequest
    @path = File.expand_path("../fixtures/aws_event.json", __dir__)
    @event = JSON.parse(File.read(@path))

    module_function

    def event
      @event
    end
  end

  module WebhookRequest
    @path = File.expand_path("../fixtures/telegram_updates.json", __dir__)
    @data = JSON.parse(File.read(@path), symbolize_names: true)

    module_function

    def text
      @data.fetch(:text)
    end

    def callback_query
      @data.fetch(:callback_query)
    end

    def command
      @data.fetch(:command)
    end
  end

  def aws_request
    AwsRequest
  end

  def webhook_request
    WebhookRequest
  end
end

Minitest::Test.include RequestsHelper
