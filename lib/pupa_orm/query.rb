# frozen_string_literal: true

require_relative "types"

module PupaORM
  class Query
    include ::PupaORM::Types::Query

    def self.build(method, table_name, ...)
      new(table_name, method).send(method, ...)
    end

    attr_reader :table_name, :filters, :query

    def initialize(table_name, query)
      @table_name   = table_name
      @filters      = {}
      @query        = EType.to_h[query] || EType.select
    end

    def to_h = { type: query, filters: filters, table_name: table_name }

    def where(**opts)
      set_filter(EFilter.where, **opts)

      self
    end

    def limit(value)
      set_filter(EFilter.limit, value)

      self
    end

    def order_by(column, direction: :asc)
      set_filter(EFilter.order_by, [ column, direction ])

      self
    end

    def find(id)
      where(id: id).limit(1)
    end

    private def set_filter(filter, value)
      case value
      in Hash
        @filters[filter] ||= {}
        @filters[filter].merge!(value)
      else
        @filters[filter] = value
      end
    end
  end
end
