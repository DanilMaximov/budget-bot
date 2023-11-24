# frozen_string_literal: true

require "./src/shared/model/model"

Message = Shared::Model.define(:message_id, :date)
Chat    = Shared::Model.define(:id, :username, :first_name, :type)

TelegramUpdate = Shared::Model.define(:update_id, :data, :type, chat: Chat, message: Message) do
  def self.build_from_webhook_request(payload)
    type = case payload
    in update_id:, message: { chat: { type: "private" } => chat, text: String => data } => message
      data.start_with?("/") ? :command : :message
    in update_id:, callback_query: { message: { chat: { type: "private" } => chat } => message, data: data }
      :callback_query
    else
      raise Shared::Model::BuildError, "Invalid update event received: #{payload.to_json}"
    end

    build(update_id:, data:, type:, chat:, message:)
  end
end
