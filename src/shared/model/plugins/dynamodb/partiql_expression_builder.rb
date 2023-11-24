module Plugins
  module DynamoDB
    class PartiQLExpressionBuilder < Struct.new(:type, :table_name, :options)
      CONDITION_EXPRESSIONS = {
        where: {
          statement: "WHERE".freeze,
          attributes: {
            s_format: proc { "#{_1} = #{format_value(_2)}" },
            delimiter: " AND ".freeze
          },
          format: "%{statement} %{attributes}".freeze
        },
        order_by: {
          statement: "ORDER BY".freeze,
          attributes: {
            s_format: proc { "#{_1} #{_2.upcase}" },
            delimiter: "".freeze
          },
          format: "%{statement} %{attributes}".freeze
        }
      }.freeze

      EXPRESSIONS = {
        select: {
          statement: "SELECT * FROM %s".freeze,
          conditions:   CONDITION_EXPRESSIONS.slice(:where, :order_by).freeze,
          format: "%{statement} %{conditions}".freeze
        },
        insert: {
          statement: "INSERT INTO %s VALUES".freeze,
          attributes: {
            s_format: proc { "#{_1}: #{format_value(_2)}" },
            delimiter: ", ".freeze
          }.freeze,
          format: "%{statement} {%{attributes}}".freeze
        },
        update: {
          statement: "UPDATE %s".freeze,
          attributes: {
            s_format: proc { "SET #{_1} = #{format_value(_2)}" },
            delimiter: "\n".freeze
          }.freeze,
          conditions: CONDITION_EXPRESSIONS.slice(:where).freeze,
          returning:    "ALL NEW *".freeze,
          format: "%{statement} %{attributes} %{conditions}%{returning}".freeze
        },
        delete: {
          statement: "DELETE FROM %s".freeze,
          conditions: CONDITION_EXPRESSIONS.slice(:where).freeze,
          returning: "ALL OLD *".freeze,
          format: "%{statement} %{conditions} %{returning}".freeze
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
        expression[:format] % { statement:, attributes:, conditions:, returning:, }
      end
      
      private 
      
      def params = options.slice(*PARAMMED_CONDITIONS)

      def expression = EXPRESSIONS[type] || raise("Invalid Expression Type: #{type}") 
      def expression_attributes_format = expression.dig(:attributes, :s_format)
      def expression_attributes_delimiter = expression.dig(:attributes, :delimiter)

      def statement 
        expression[:statement] % table_name
      end

      def conditions
        return nil unless expression[:conditions]

        options.slice(*CONDITION_EXPRESSIONS.keys).map do |condition, value|
          condition_expression = expression[:conditions][condition]
        
          self.class.new(condition, '', values: value).build
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
