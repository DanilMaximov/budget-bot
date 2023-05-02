# frozen_string_literal: true

require_relative "base_client"
require "date"

module Clients
  class Notion < BaseClient
    BASE_URL = "https://api.notion.com/v1"

    def create_page(expense:, amount:, category:)
      page = { parent: {}, properties: {} }

      page[:parent][:database_id] = ENV.fetch("NOTION_DATABASE_ID")

      # TODO: Introduce Parser OStruct
      page[:properties].tap do |properties|
        properties[:Expense] = { title: [ { text: { content: expense } } ] }
        properties[:Amount]  = { number: amount }
        properties[:Type]    = { select: { name: category } }
        properties[:Date]    = { date: { start: Date.today.iso8601 } }
      end

      make_request("pages", params: page, method: :post)
    end

    private

    def base_url        = BASE_URL
    def default_headers = {
      "Notion-Version" => "2022-06-28",
      "Content-Type"   => "application/json",
      "Authorization"  => "Bearer #{ENV.fetch("NOTION_TOKEN")}"
    }
  end
end
