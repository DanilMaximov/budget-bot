# frozen_string_literal: true

module RequestsHelper
  module AwsRequest
    PATH = File.expand_path("../fixtures/aws_event.json", __dir__)

    module_function

    def event
      JSON.parse(File.read(PATH))
    end
  end

  module WebhookRequest
    PATH = File.expand_path("../fixtures/telegram_updates.json", __dir__)

    module_function

    def text
      JSON.parse(File.read(PATH), symbolize_names: true).fetch(:text)
    end

    def callback_query
      JSON.parse(File.read(PATH), symbolize_names: true).fetch(:callback_query)
    end

    def command
      JSON.parse(File.read(PATH), symbolize_names: true).fetch(:command)
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
