# frozen_string_literal: true

require "interactor"
require "net/http"

class HttpFetcher
  include Interactor

  DEFAULT_HEADERS = {
    "Accept" => "application/json; charset=utf-8"
  }.freeze

  before :set_headers
  before :set_http

  def call
    context.response = context.http.request(context.request)

    context.fail!(errors: context.response.body) unless context.response.is_a?(Net::HTTPSuccess)

    context.response_body = JSON.parse(context.response.body)
  end

  def post(path, params = {})
    uri = compose_uri(path)

    context.request      = Net::HTTP::Post.new(uri)
    context.request.body = JSON.generate(params)

    run
  end

  def get(path, params = {})
    uri = compose_uri(path, params)

    context.request = Net::HTTP::Get.new(uri)

    run
  end

  private

  def set_headers
    context.headers.merge(Hash[DEFAULT_HEADERS]).each do |k, v|
      context.request[k] = v
    end
  end

  def set_http
    context.http = Net::HTTP.new(context.request.uri.host, context.request.uri.port).tap do |h|
      h.use_ssl     = true
      h.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
  end

  def compose_uri(path, params = {})
    URI("#{context.url}/#{path}?#{URI.encode_www_form(params)}")
  end
end
