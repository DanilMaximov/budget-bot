require 'test_helper'
require_relative '../../models/model'

describe Model do
  describe "::define" do
    it "should define a model with the given members" do
      Model.define(:id, :name).tap do |model|
        assert_equal %i[id name], model.members
        assert_includes model.ancestors, Data
      end
    end
  end

  describe "Model.define(**)" do
    let(:model) { Model.define(:id, :name) }
    let(:model_with_sub_model) do
      Model.define(:id, :name, test: Model.define(:type))
    end

    describe "::build" do
      
      it "should build a model with the given attributes" do
        model.build(id: 1, name: "test").tap do |model|
          assert_equal 1, model.id
          assert_equal "test", model.name
        end
      end
      
      it "should build a model with the given sub model" do
        model_with_sub_model.build(id: 1, name: "test", test: { type: "foo"}).tap do |model|
          assert_equal 1, model.id
          assert_equal "test", model.name
          assert_equal "foo", model.test.type
        end
      end
      
      it "should raise an error if missing defined attr" do
        assert_raises(Model::Mixin::BuildError) do
          model.build(id: 1)
        end
      end
      
      it "should raise an error if the given sub model is invalid" do
        assert_raises(Model::Mixin::BuildError) do
          model_with_sub_model.build(id: 1, name: "test", test: { unknown: "foo"})
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
        model_with_sub_model.build(id: 1, name: "test", test: { type: "foo"}).tap do |model|
          assert_equal({ id: 1, name: "test", test: { type: "foo" } }, model.to_h)
        end
      end
    end
  end
end