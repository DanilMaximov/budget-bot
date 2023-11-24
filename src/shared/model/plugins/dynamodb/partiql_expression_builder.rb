# frozen_string_literal: true

module Plugins
  module DynamoDB
    class PartiQLExpressionBuilder < Struct.new(:type, :table_name, :options)
      CONDITION_EXPRESSIONS = {
        where:    {
          statement:  "WHERE",
          attributes: {
            s_format:  proc { "#{_1} = #{format_value(_2)}" },
            delimiter: " AND "
          },
          format:     "%{statement} %{attributes}"
        },
        order_by: {
          statement:  "ORDER BY",
          attributes: {
            s_format:  proc { "#{_1} #{_2.upcase}" },
            delimiter: ""
          },
          format:     "%{statement} %{attributes}"
        }
      }.freeze

      EXPRESSIONS = {
        select: {
          statement:  "SELECT * FROM %s",
          conditions: CONDITION_EXPRESSIONS.slice(:where, :order_by).freeze,
          format:     "%{statement} %{conditions}"
        },
        insert: {
          statement:  "INSERT INTO %s VALUES",
          attributes: {
            s_format:  proc { "#{_1}: #{format_value(_2)}" },
            delimiter: ", "
          }.freeze,
          format:     "%{statement} {%{attributes}}"
        },
        update: {
          statement:  "UPDATE %s",
          attributes: {
            s_format:  proc { "SET #{_1} = #{format_value(_2)}" },
            delimiter: "\n"
          }.freeze,
          conditions: CONDITION_EXPRESSIONS.slice(:where).freeze,
          returning:  "ALL NEW *",
          format:     "%{statement} %{attributes} %{conditions}%{returning}"
        },
        delete: {
          statement:  "DELETE FROM %s",
          conditions: CONDITION_EXPRESSIONS.slice(:where).freeze,
          returning:  "ALL OLD *",
          format:     "%{statement} %{conditions} %{returning}"
        },
        **CONDITION_EXPRESSIONS
      }.freeze

      class << self
        def format_value(value)
          value.is_a?(String) ? "'#{value}'" : value
        end
      end

      def initialize(type, table_name, **options)
        super(type, table_name, options)
      end

      def build
        expression[:format] % { statement:, attributes:, conditions:, returning: }
      end

      private

      def params = options.slice(*PARAMMED_CONDITIONS)

      def expression                      = EXPRESSIONS[type] || raise("Invalid Expression Type: #{type}")
      def expression_attributes_format    = expression.dig(:attributes, :s_format)
      def expression_attributes_delimiter = expression.dig(:attributes, :delimiter)

      def statement
        expression[:statement] % table_name
      end

      def conditions
        return nil unless expression[:conditions]

        options.slice(*CONDITION_EXPRESSIONS.keys).map do |condition, value|
          self.class.new(condition, "", values: value).build
        end.join(" ")
      end

      def attributes
        return nil unless expression[:attributes]

        options.delete(:values)
          .map { expression_attributes_format[_1, _2] }
          .join(expression_attributes_delimiter)
      end

      def returning
        return nil unless expression[:returning]

        expression[:returning]
      end
    end
  end
end
