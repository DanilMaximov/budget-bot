# frozen_string_literal: true

module PupaORM
  module Helpers
    module Attributes
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        @__attributes = {}

        DEFAULT_OPTIONS = {
          type:     String,
          required: false
        }

        def attribute(name, type)
          set_attribute(name, type)
        end

        def attributes
          @__attributes ||= {}
          @__attributes.freeze
        end

        private def set_attribute(name, opts = DEFAULT_OPTIONS.dup)
          @__attributes     ||= {}
          @__attributes[name] = opts
        end
      end
    end
  end
end
