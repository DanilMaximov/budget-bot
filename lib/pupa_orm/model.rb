# frozen_string_literal: true

require_relative "query"
require_relative "relation"
require_relative "types"
require_relative "helpers/table_name"
require_relative "helpers/attributes"

module PupaORM
  class Model
    include Helpers::TableName
    include Helpers::Attributes

    class << self
      def init_by_query(...)
        query = Query.build(__callee__, table_name, ...)

        Relation.new(self, query)
      end

      def init_from_response(**attrs)
        new(changed: false, **attrs)
      end

      Types::Model::EQueryMethods.to_a.each do |m|
        alias_method m, :init_by_query
      end
    end

    def initialize(changed: true, **new_attrs)
      @changed = changed

      @column_names  = self.class.attributes.keys
      @column_names += new_attrs.keys if @column_names.empty?

      @column_names.each { |c_name| self[c_name] = new_attrs[c_name] }
    end

    def attributes
      @column_names.each_with_object({}) do |c_name, attrs|
        attrs[c_name] = public_send(c_name)
      end
    end

    alias_method :to_h, :attributes

    private def []=(attr_name, value)
      instance_variable_set("@#{attr_name}", value)

      define_singleton_method attr_name do
        instance_variable_get("@#{attr_name}")
      end

      define_singleton_method "#{attr_name}=" do |new_value|
        instance_variable_set("@#{attr_name}", new_value)
        instance_variable_set(:@changed, true) unless instance_variable_get(:@changed)
      end
    end

    def self.method_added(m)
      return unless PupaORM::Model.instance_methods(false).include?(m)

      raise "Method #{m} is not allowed in #{self} class"
    end
  end
end
