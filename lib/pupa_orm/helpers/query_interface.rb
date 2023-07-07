# frozen_string_literal: true

require "forwardable"
require_relative "../types"

module PupaORM
  module Helpers
    module QueryInterface
      def self.included(base)
        base.extend(QueryIntanceMethodsOverridding)
      end

      module QueryIntanceMethodsOverridding
        def define_delegated_query_method_overridings
          Types::Model::EAllowedMethods.to_a.each { delegate_query_method(_1) }
        end

        def delegate_query_method(name)
          class_eval(<<-END, __FILE__, __LINE__ + 1)
            def #{name}(...)
              @query.public_send(:#{name}, ...)
              
              self
            end
          END
        end
      end
    end
  end
end
