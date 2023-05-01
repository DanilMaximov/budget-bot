# frozen_string_literal: true

require_relative "http_client"

class NotionClient
  BASE_URL = "https://api.notion.com/v1"

  def self.build
    token   = ENV.fetch("NOTION_TOKEN")
    headers = {
      "Notion-Version" => "2022-06-28",
      "Content-Type"   => "application/json",
      "Authorization"  => "Bearer #{token}"
    }

    new(HttpClient.new(BASE_URL, headers: headers))
  end

  def initialize(http_client)
    @http_client = http_client
  end

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

  def make_request(resource, params: {}, method: :get)
    @http_client.public_send(method, resource, params)
  end
end
