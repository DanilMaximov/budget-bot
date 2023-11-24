# frozen_string_literal: true

require "logger"
require "aws-sdk-dynamodb"
require_relative "partiql_expression_builder"

module Plugins
  module DynamoDB
    module Item
      def self.included(base)
        base.extend ClassMethods
        base.include InstanceMethods
      end

      module InstanceMethods
        def update(**options)
          raise "Cannot update an item without an id" unless defined?(id)

          self.class.update(where: { id: id }, **options)
        end

        def delete(**options)
          raise "Cannot delete an item without an id" unless defined?(id)

          self.class.delete(where: { id: id }, **options)
        end
      end

      module ClassMethods
        def build_from_dynamodb_item(items)
          return nil if items.empty?

          items.map do |item|
            build(**item.transform_keys(&:to_sym))
          end
        end

        def find_by(**options)
          execute_expression(:select, where: options, params: { limit: 1 })
            .then { |result| build_from_dynamodb_item(result.items)&.first }
        end

        def where(**options)
          filters = options.slice(:order_by)
          params  = options.slice(:limit)
          values  = options.except(*(filters.keys + params.keys))

          execute_expression(:select, params:, where: values, **filters)
            .then { |result| build_from_dynamodb_item(result.items) }
        end

        def update(options)
          filters = options.slice(:order_by, :where)
          params  = options.slice(:limit)
          values  = options.except(*(filters.keys + params.keys))

          execute_expression(:update, params:, values:, **filters)
            .then { |result| build_from_dynamodb_item(result.items) }
        end

        def create(options)
          execute_expression(:insert, values: options)
        end

        def delete(**options)
          filters = options.slice(:order_by)
          params = options.slice(:limit)
          values  = options.except(*(filters.keys + params.keys))

          execute_expression(:delete, params:, where: values, **filters)
        end

        private

        def execute_expression(type, params: {}, **options)
          expression = PartiQLExpressionBuilder.new(type, table_name, **options).build

          logger.info("DDB Request Expression: #{expression}")

          connection.execute_statement(statement: expression, **params).tap do |result|
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

        def build_from_dynamodb_item(items)
          return nil if items.empty?

          items.map do |item|
            build(**item.transform_keys(&:to_sym))
          end
        end
      end
    end
  end
end
