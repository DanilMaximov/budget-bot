# frozen_string_literal: true

require_relative "../model"
require "logger"
require "aws-sdk-dynamodb"

module Plugins
  module DynamoDB
    module Item
      def self.included(base)
        base.extend ClassMethods
        base.include InstanceMethods
      end

      module InstanceMethods
        def update(**options)
          self.class.update(where: { id: id }, **options)
        end

        def delete(**options)
          self.class.delete(where: { id: id }, **options)
        end
      end

      module ClassMethods
        class ExpressionBuilder < Struct.new(:type, :table_name, :filters)
          FILTER_CONDITIONS = {
            where:    ->(attrs) { "WHERE #{build_where_attrs(attrs)}" },
            limit:    :limit,
            order_by: ->(attrs) { "ORDER BY #{build_order_by_attrs(attrs)}" }
          }

          EXPRESSIONS = {
            select: {
              beginning: "SELECT * FROM %s",
              filters:   FILTER_CONDITIONS.slice(:where, :limit, :order_by)
            },
            insert: {
              beginning: "INSERT INTO %s",
              filters:   {
                values: ->(attrs) { "VALUES {#{build_insert_attrs(attrs)}}" }
              }
            },
            update: {
              beginning: "UPDATE %s",
              filters:   {
                values: ->(attrs) { build_update_attrs(attrs).to_s },
                **FILTER_CONDITIONS.slice(:where, :limit, :order_by)
              },
              ending:    "ALL NEW *"
            },
            delete: {
              beginning: "DELETE FROM %s",
              filters:   FILTER_CONDITIONS.slice(:where, :limit, :order_by)
            }
          }

          EXPRESSION = "%{expression}\n%{conditions}\n%{ending}"
          LOGGER     = ::Logger.new($stdout)

          def initialize(type, table_name, filters = {}) = super

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
            params     = {}

            beginning  = expression[:beginning] % table_name
            ending     = expression[:ending] || ""

            conditions = filters.map do |name, value|
              filter = expression.dig(:filters, name)

              next unless filter

              case filter
              in Proc then filter.call(value)
              in String then format(filter, value)
              in Symbol then params[filter] = value
                             nil
              end
            end.compact

            {
              statement: format(EXPRESSION, expression: beginning, conditions: conditions.join("\n"), ending: ending),
              **params
            }
          end
        end

        def build_from_dynamodb_item(items)
          return nil if items.empty?
          return build(**items[0].transform_keys(&:to_sym)) if items.length == 1

          items.map do |item|
            build(**item.transform_keys(&:to_sym))
          end
        end

        def find_by(**options)
          execute_expression(:select, where: options, limit: 1).tap do |result|
            return build_from_dynamodb_item(result.items)
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
          filters = options.slice(:limit, :order_by)
          values  = options.except(*filters.keys)

          execute_expression(:delete, where: values, **filters)
        end

        private

        def execute_expression(type, **options)
          expression = ExpressionBuilder.new(type, table_name, **options).build

          logger.info("DDB Request Expression: #{expression}")

          connection.execute_statement(**expression).tap do |result|
            logger.info("DDB Response: #{result.to_h}")
          end
        end

        def connection
          defined?(::DDB) || raise("Global DDB Client Not Configured")

          ::DDB
        end

        def logger
          @_logger ||= (defined?(::LOGGER) && ::LOGGER) || ::Logger.new($stdout)
        end
      end
    end
  end
end
