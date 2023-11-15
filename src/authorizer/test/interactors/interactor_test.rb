require "test_helper"
require_relative "../../interactos/interactor"

describe Interactor do
  let(:delegate_class) { Data.define(:param1, :param2, :param3) }
  let(:delegate_object) { delegate_class.new(param1: 1, param2: 2, param3: 3) }
  let(:interactor_class) {
    Interactor.define(:param1, :param2) do
      def call
        context.result = param1 + param2
      end

      def custom_method = nil
    end
  }

  describe "::define" do
    it "defines an interactor class" do
      _(interactor_class.members).must_equal [ :param1, :param2, :context ]
      _(interactor_class.instance_methods(true)).must_include :custom_method
    end
  end

  describe "::[]" do
    it "creates an interactor object with delegated params" do
      interactor = interactor_class[delegate_object]

      _(interactor.param1.object_id).must_equal delegate_object.param1.object_id
      _(interactor.param2.object_id).must_equal delegate_object.param2.object_id
      _(interactor.context).must_equal OpenStruct.new(errors: [], success: true)
    end
  end

  describe "#execute" do
    it "executes the interactor" do
      interactor = interactor_class[delegate_object]

      interactor.execute

      _(interactor.context.result).must_equal 3
      _(interactor.context.success).must_equal true
      _(interactor.context.errors).must_be_empty
    end

    it "executes a failure interactor and sets error in context" do
      interactor_class = Interactor.define(:param1, :param2) do
        def call
          raise "error"
        end
      end

      interactor = interactor_class[delegate_object]

      interactor.execute

      _(interactor.context.errors.size).must_equal 1
      _(interactor.context.errors.first.message).must_equal "error"
      _(interactor.context.success).must_equal false
    end
  end
end
