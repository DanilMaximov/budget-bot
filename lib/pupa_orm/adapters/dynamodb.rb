# frozen_string_literal: true

require_relative "base"
require_relative "../types"

module PupaORM
  module Adapters
    class Dynamodb < Base
      Request = Data.define(:query) do
        def to_h = { expression: to_s }
        def to_s = ExpressionBuilder.build(**query.to_h)
      end

      class ExpressionBuilder < Struct.new(:type, :table_name, :filters)
        FILTER_EXPRESSIONS = {
          Types::Query::EFilter.where    => "WHERE %s",
          Types::Query::EFilter.limit    => "LIMIT %s",
          Types::Query::EFilter.order_by => "ORDER BY %s %s"
        }

        START_EXPRESSIONS = {
          Types::Query::EType.select => 'SELECT * FROM "%s"',
          Types::Query::EType.insert => 'INSERT INTO "%s"',
          Types::Query::EType.update => 'UPDATE "%s"',
          Types::Query::EType.delete => 'DELETE FROM "%s"'
        }

        def self.build(...) = new(...).build

        def build
          expression = START_EXPRESSIONS[type] % table_name

          expression += " " + filters_expression if filters

          expression
        end

        private

        def filters_expression
          filters.map do |filter, value|
            expr = case filter
            when Types::Query::EFilter.where then build_where_clause(value)
            when Types::Query::EFilter.order_by then build_order_by_clause(value)
            else value
            end

            FILTER_EXPRESSIONS[filter] % expr
          end.join(" ")
        end

        def build_where_clause(attrs)
          attrs.map do |key, value|
            case value
            in String then "#{key} = '#{value}'"
            in Integer then "#{key} = #{value}"
            end
          end.join(" AND ")
        end

        def build_order_by_clause(attrs)
          [ attrs.first, attrs.last.upcase ]
        end
      end

      def build_request(query)
        Request[query]
      end

      def execute_request(request)
        @db.client.execute_statement(request.to_h).items
      end
    end
  end
end
