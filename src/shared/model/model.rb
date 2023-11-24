# frozen_string_literal: true

module Shared
  class Model < Data
    BuildError = Class.new(StandardError)

    def self.define(*args, **sub_models)
      Class.new(super(*args, *sub_models.keys)).tap do |model|
        model.instance_variable_set(:@_sub_models, sub_models)
        model.include Mixin
      end
    end

    module Mixin
      def self.included(base)
        base.extend ClassMethods
        base.include InstanceMethods
      end

      module InstanceMethods
        def to_h
          members.each_with_object({}) do |member, hash|
            hash[member] = if (value = send(member)).is_a?(Model)
              value.to_h
            else
              value
            end
          end
        end
      end

      module ClassMethods
        def build(**options)
          new(**build_options(options))
        end

        def build_options(options)
          sliced_options = options.slice(*members)

          validate!(sliced_options.keys)

          sliced_options.each_with_object({}) do |(key, value), hash|
            hash[key] = if (sub_model = sub_models[key])
              sub_model.build(**value)
            else
              value
            end

            hash
          end
        end

        def validate!(options)
          expected_keys = Set[*members]
          received      = Set[*options]

          raise BuildError, "Invalid keys received: #{(received - expected_keys).to_a.join(", ")}" unless received == expected_keys
        end

        def sub_models = instance_variable_get(:@_sub_models)
      end
    end
  end
end
