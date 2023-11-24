# frozen_string_literal: true

require "./src/interactors/http_fetcher"

module Clients
  class Base
    EMPTY_HASH = {}.freeze

    attr_reader :http_client

    def initialize(client = HttpFetcher)
      @http_client = client.new(
        url:     base_url,
        headers: default_headers
      )
    end

    def request_succeed? = @http_client.context.success?
    def request_errors   = @http_client.context.errors

    private

    def make_request(resource, params: {}, method: :get)
      @http_client.public_send(method, resource, params)
    end

    def base_url        = raise(NotImplementedError)
    def default_headers = Hash[EMPTY_HASH]
  end
end
