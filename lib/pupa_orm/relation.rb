# frozen_string_literal: true

require "set"
require "forwardable"

require_relative "connection"
require_relative "helpers/query_interface"

module PupaORM
  class Relation
    EMPTY_ARRAY = [].freeze
    TRIGGERS    = Set[
      :inspect,
      :to_s,
      *Relation.instance_methods(false),
      *Array.instance_methods(false) - Relation.instance_methods(false),
    ].freeze

    Records = Data.define(:items)

    extend Forwardable
    include Helpers::QueryInterface

    define_delegated_query_method_overridings
    def_delegators Connection, :exec_query, :build

    def initialize(model, query)
      @model   = model
      @query   = query
      @records = Records.new(EMPTY_ARRAY.dup)
    end

    def execute
      res_data = exec_query(@query).data
        .map { |rec| @model.init_from_response(**rec) }

      set_records(res_data)
    end

    def raw_query = build(@query).to_s

    def set_records(data)
      @records = @records.with(items: data)
    end

    def method_missing(meth, ...)
      return super unless trigger_meth?(meth)

      execute.items.public_send(meth, ...)
    end

    def respond_to_missing?(method, *)
      super || trigger_meth?(method)
    end

    def trigger_meth?(m) = TRIGGERS.include?(m)
  end
end
