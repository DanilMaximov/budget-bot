# frozen_string_literal: true

require_relative "../model"
require "logger"
$logger = Logger.new($stdout)

module Plugins
  module DynamoDB
    module Item
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        class ExpressionBuilder < Struct.new(:type, :table_name, :filters)
          FILTER_CONDITIONS = {
            where: ->(attrs) { "WHERE #{build_where_attrs(attrs)}" },
            limit: ->(attrs) { "LIMIT #{attrs}" },
            order_by: ->(attrs) { "ORDER BY #{build_order_by_attrs(attrs)}" }
          }

          EXPRESSIONS = {
            select: {
              beginning: "SELECT * FROM %s",
              filters: FILTER_CONDITIONS.slice(:where, :limit, :order_by)
            },
            insert: {
              beginning: "INSERT INTO %s",
              filters: {
                values: ->(attrs) { "VALUES {#{build_insert_attrs(attrs)}}" }
              }
            },
            update: {
              beginning: "UPDATE %s",
              filters: {
                values: ->(attrs) { build_update_attrs(attrs).to_s },
                **FILTER_CONDITIONS.slice(:where, :limit, :order_by)
              },
              ending: "ALL NEW *"
            },
            delete: {
              beginning: "DELETE FROM %s",
              filters: FILTER_CONDITIONS.slice(:where, :limit, :order_by)
            }
          }

          EXPRESSION = "%{expression}\n%{conditions}\n%{ending}"

          class << self
            def build_where_attrs(attrs)
              attrs.map { |key, value| "#{key} = #{format_value(value)}" }.join(" AND ")
            end

            def build_insert_attrs(attrs)
              attrs.map { |key, value| "#{format_value(key)}: #{format_value(value)}" }.join(", ")
            end

            def build_update_attrs(attrs)
              attrs.map { |key, value| "SET #{key} = #{format_value(value)}" }.join("\n")
            end

            def build_order_by_attrs(attrs)
              "#{attrs.first} #{attrs.last.upcase}"
            end

            def format_value(value)
              value.is_a?(String) ? "'#{value}'" : value
            end
          end

          def build
            expression = EXPRESSIONS[type]

            beginning  = expression[:beginning] % table_name
            ending     = expression[:ending] || ""

            conditions = filters.map do |name, value|
              filter = expression.dig(:filters, name)

              next unless filter

              case filter
              in Proc then filter.call(value)
              in String then format(filter, value)
              end
            end

            format(EXPRESSION, expression: beginning, conditions: conditions.join("\n"), ending: ending)
          end
        end

        def build_from_dynamodb_item(items)
          return build(**items[0]) if items.length == 1

          items.map do |item|
            build(**item)
          end
        end

        def find_by(**options)
          execute_expression(:select, limit: 1).tap do |result|
            build_from_dynamodb_item(result.items)
          end
        end

        def where(**options)
          filters = options.slice(:limit, :order_by)
          values  = options.except(*filters.keys)

          execute_expression(:select, where: values, **filters).tap do |result|
            return build_from_dynamodb_item(result.items)
          end
        end

        def update(options)
          filters = options.slice(:limit, :order_by, :where)
          values  = options.except(*filters.keys)

          execute_expression(:update, values: values, **filters).tap do |result|
            return build_from_dynamodb_item(result.items)
          end
        end

        def create(options)
          execute_expression(:insert, values: options)
        end

        def delete(**options)
          filters = options.slice(:limit, :order_by, :where)

          execute_expression(:delete, **filters)
        end

        private

        def execute_expression(type, **options)
          expression = ExpressionBuilder.new(type, table_name, **options).build

          connection.execute_statement(
            statement: expression
          )
        end

        def connection
          @_connection ||= Aws::DynamoDB::Resource.new(client: Aws::DynamoDB::Client.new)
        end
      end
    end
  end
end
