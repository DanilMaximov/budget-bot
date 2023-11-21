# frozen_string_literal: true

require_relative "model"

Message = Model.define(:message_id, :date)
Chat    = Model.define(:id, :username, :first_name, :type)

class TelegramUpdate < Model.define(:update_id, :data, :type, chat: Chat, message: Message)
  def self.build_from_webhook_request(payload)
    type = case payload
    in update_id: id, message: { chat: { type: "private" } => chat, text: String => data } => message
      data.start_with?("/") ? :command : :message
    in update_id: id, callback_query: { message: { chat: { type: "private" } => chat } => message, data: data }
      :callback_query
    else
      raise BuildError, "Invalid update event received: #{payload.to_json}"
    end

    build(
      update_id: id,
      data: data,
      type: type,
      chat: chat,
      message: message
    )
  end
end
