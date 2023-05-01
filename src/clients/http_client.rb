# frozen_string_literal: true

require "net/http"
require "json"

class HttpClient
  DEFAULT_HEADERS = {
    "Accept" => "application/json; charset=utf-8"
  }.freeze

  def initialize(base_url, headers: {})
    @base_url = base_url
    @headers  = DEFAULT_HEADERS.merge(headers)
  end

  def post(path, params = {})
    uri = compose_uri(path)

    request = Net::HTTP::Post.new(uri)
    request.body = JSON.generate(params)

    process(request)
  end

  private

  def process(request)
    set_headers(request)

    response = make_request(request)

    JSON.parse(response.body)
  end

  def make_request(request)
    http(request.uri.host, request.uri.port)
      .request(request)
  end

  def compose_uri(path, params = {})
    URI("#{@base_url}/#{path}?#{URI.encode_www_form(params)}")
  end

  def set_headers(req)
    @headers.each do |k, v|
      req[k] = v
    end
  end

  def http(host, port)
    Net::HTTP.new(host, port).tap do |h|
      h.use_ssl     = true
      h.verify_mode = OpenSSL::SSL::VERIFY_PEER
    end
  end
end
