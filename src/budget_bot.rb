# frozen_string_literal: true

require_relative "clients/notion_client"

require "telegram/bot"
require "dotenv/load"

USERS = ENV.fetch("TG_USERS").split(",").map(&:to_i).freeze

TOKEN  = ENV.fetch("TG_TOKEN")
NOTION = NotionClient.build

module BudgetBot
  class Application
    MSG_REGEXP = /^((\s?)(\w+|[А-Яа-я]))* \d+ \w+$/

    def self.start
      new.start
    end

    def initialize
      @bot = Telegram::Bot::Client.new(TOKEN)
    end

    def start
      @bot.listen { |message| puts handle_message(message) }
    end

    private

    def handle_message(msg)
      return "Wrong Event Type" unless msg in Telegram::Bot::Types::Message
      return "Wrong Message Format" unless msg.text in MSG_REGEXP
      return "Access Denied for #{msg.from.first_name} #{msg.from.last_name} #{msg.from.id}" unless USERS.include? msg.from.id

      expense_options = parse_expense(msg.text)

      NOTION.create_page **expense_options

      "Success! #{expense_options} saved"
    end

    def parse_expense(message)
      {
        expense: message[0..message.index(/\s\d/)].strip,
        amount: message[message.index(/\s\d/)..message.index(/\d\s/)].to_i,
        category: message[(message.index(/\d\s/) + 1)..].strip.capitalize
      }
    end
  end
end
