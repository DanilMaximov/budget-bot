# frozen_string_literal: true

require "test_helper"
require_relative "../../model/model"

describe Shared::Model do
  let(:described_class) { Shared::Model }

  describe "::define" do
    it "should define a model with the given members" do
      described_class.define(:id, :name).tap do |model|
        assert_equal %i[id name], model.members
        assert_includes model.ancestors, Data
      end
    end
  end

  describe "Model.define(**)" do
    let(:model) { described_class.define(:id, :name) }
    let(:model_with_sub_model) do
      described_class.define(:id, :name, test: described_class.define(:type))
    end

    describe "::build" do
      it "should build a model with the given attributes" do
        model.build(id: 1, name: "test").tap do |model|
          assert_equal 1, model.id
          assert_equal "test", model.name
        end
      end

      it "should build a model with the given sub model" do
        model_with_sub_model.build(id: 1, name: "test", test: { type: "foo" }).tap do |model|
          assert_equal 1, model.id
          assert_equal "test", model.name
          assert_equal "foo", model.test.type
        end
      end

      describe "when invalid attributes are given" do
        it "should raise an error if missing defined attr" do
          assert_raises(described_class::BuildError) do
            model.build(id: 1)
          end
        end

        describe "when invalid submodel lazily loaded" do
          it "should raise an error if the given sub model is invalid" do
            assert_raises(described_class::BuildError) do
              model_with_sub_model.build(id: 1, name: "test", test: { unknown: "foo" }).test
            end
          end
        end
      end
    end

    describe "#to_h" do
      it "should return a hash with the model attributes" do
        model.build(id: 1, name: "test").tap do |model|
          assert_equal({ id: 1, name: "test" }, model.to_h)
        end
      end

      it "should return a hash with the model attributes and sub model" do
        model_with_sub_model.build(id: 1, name: "test", test: { type: "foo" }).tap do |model|
          assert_equal({ id: 1, name: "test", test: { type: "foo" } }, model.to_h)
        end
      end
    end
  end
end
