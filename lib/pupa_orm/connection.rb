# frozen_string_literal: true

require_relative "adapters/dynamodb"

module PupaORM
  class Connection
    def self.exec_query(query)
      adapter.process(query)
    end

    def self.build(query)
      adapter.build_query(query)
    end

    def self.adapter
      @adapter ||= Adapters::Dynamodb.new(DB)
    end
  end
end
