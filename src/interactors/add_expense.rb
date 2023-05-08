# frozen_string_literal: true

require "interactor"
require "forwardable"

require_relative "../clients/notion"

class AddExpense
  include Interactor
  extend Forwardable

  MSG_REGEXP = /^((\s?)(\w+|[А-Яа-я]))* \d+ \w+$/

  def_delegators :context, :text

  before do
    context.notion = Clients::Notion.new
  end

  def call
    add_expense

    return if context.notion.request_succeed?

    context.fail!(error: notion_client.request_errors)
  end

  private

  def expense_attributes
    context.fail!(error: "Wrong Telegram Message Format") unless text in MSG_REGEXP

    {
      expense:  text[0..text.index(/\s\d/)].strip,
      amount:   text[text.index(/\s\d/)..text.index(/\d\s/)].to_i,
      category: text[(text.index(/\d\s/) + 1)..].strip.capitalize
    }
  end

  def add_expense
    context.notion.create_page(**expense_attributes)
  end
end
