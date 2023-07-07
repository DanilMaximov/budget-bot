# frozen_string_literal: true

module PupaORM
  module Helpers
    module TableName
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def [](table_name)
          Class.new(self) do
            @_table_name = table_name
          end
        end

        def inherited(klass)
          klass.instance_variable_set(:@_table_name, @_table_name)
        end

        def table_name = @_table_name || name.downcase
      end
    end
  end
end
