# frozen_string_literal: true

module PupaORM
  module Adapters
    class Base
      Response = Data.define(:data)

      def initialize(db)
        @db = db
      end

      def process(query)
        request = build_request(query)

        Response[execute_request(request)]
      end

      def build_query(query)
        build_request(query).to_s
      end

      private def build_request(query)     = raise(NotImplementedError)
      private def execute_request(request) = raise(NotImplementedError)
    end
  end
end
