# frozen_string_literal: true

require "forwardable"
require "ostruct"

class Interactor
  DataWrapper = lambda do |delegators|
    Data.define(*delegators, :context) do
      extend Forwardable

      def_delegators :context, :errors, :success, :success?, :failure?

      def self.[](context)
        context_obj = OpenStruct.new(errors: [], success: true)
        options     = context.to_h.slice(*members)

        new(**options, context: context_obj)
      end

      def execute
        call
      rescue => e
        context.errors << e
        context.success = false
      end

      def call = raise(NotImplementedError)
    end
  end

  def self.define(*delegators, &block)
    DataWrapper[delegators].tap do |data|
      data.class_eval(&block)
    end
  end
end
