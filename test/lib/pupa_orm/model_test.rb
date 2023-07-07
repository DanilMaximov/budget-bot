# frozen_string_literal: true

require "test_helper"
require "mocha/minitest"

class TestModel < PupaORM::Model
end

class TestModel1 < PupaORM::Model["custom_name"]
  attribute :id, Integer
end

class PupaORMModelTest < Minitest::Test
  def setup
    @model = TestModel
  end

  def test_relation_returned_on_query_method_call
    assert_kind_of PupaORM::Relation, @model.find(1)
  end

  def test_relation_returned_on_query_method_chaining
    assert_kind_of PupaORM::Relation, @model.where(name: "test").limit(10).order_by(:id, direction: :desc)
  end

  def test_raw_query
    assert_equal "SELECT * FROM \"testmodel\" WHERE id = 1 LIMIT 1", @model.find(1).raw_query
  end

  def relation_execution
    PupaORM::Connection.adapter.expects(:execute_request).at_least_once

    @model.find(1).execute
  end
end

class PupaORMModelTestAttributes < Minitest::Test
  def test_model_attributes
    assert_equal({}, TestModel.attributes)
  end

  def test_model_attributes_with_custom_name
    assert_equal({ id: Integer }, TestModel1.attributes)
  end

  def test_relation_execution_with_attributed_model
    relation = TestModel1.where(name: "test").limit(10).order_by(:id, direction: :desc)

    PupaORM::Connection.adapter.expects(:execute_request).at_least_once.returns([ { id: "stubbed_item" } ])

    assert_equal "stubbed_item", relation.to_a.first.id
  end

  def test_relation_execution_with_not_attributed_model
    relation = TestModel.where(name: "test").limit(10).order_by(:id, direction: :desc)

    PupaORM::Connection.adapter.expects(:execute_request).at_least_once.returns([ { id: "stubbed_item", name: "test" } ])

    assert_equal({ id: "stubbed_item", name: "test" }, relation.to_a.first.to_h)
  end
end

class PupaORMModelTestTableName < Minitest::Test
  def test_table_name
    assert_equal "testmodel", TestModel.table_name
  end

  def test_custom_table_name
    assert_equal "custom_name", TestModel1.table_name
  end
end

class PupaORMModelSelectMethodsRawQueriesTest < Minitest::Test
  def setup
    @model = TestModel
  end

  def test_where_method
    relation = @model.where(id: 1)

    assert_equal 'SELECT * FROM "testmodel" WHERE id = 1', relation.raw_query
  end

  def test_where_method_with_several_options
    relation = @model.where(id: 1, name: "test")

    assert_equal "SELECT * FROM \"testmodel\" WHERE id = 1 AND name = 'test'", relation.raw_query
  end

  def test_where_method_with_chaining
    relation = @model.where(id: 1).where(name: "test")

    assert_equal "SELECT * FROM \"testmodel\" WHERE id = 1 AND name = 'test'", relation.raw_query
  end

  def test_find_method
    relation = @model.find(1)

    assert_equal 'SELECT * FROM "testmodel" WHERE id = 1 LIMIT 1', relation.raw_query
  end

  def test_filters_method_chaining
    relation = @model.where(id: 1).where(name: "test").limit(10).order_by(:id, direction: :desc)

    assert_equal "SELECT * FROM \"testmodel\" WHERE id = 1 AND name = 'test' LIMIT 10 ORDER BY id DESC", relation.raw_query
  end
end

class PupaORMModelSelectMethodsQueriesTest < Minitest::Test
  include PupaORMHelper

  def setup
    @model = TestModel
  end

  def test_find_method
    relation        = @model.find(1)
    expected_result = [ { id: "stubbed_item", name: "test" } ]

    mock_execute_request(expected_result)

    assert_equal expected_result[0], relation[0].to_h
  end

  def test_where_method
    relation        = @model.where(name: "test")
    expected_result = [ { id: "stubbed_item", name: "test" }, { id: "stubbed_item2", name: "test" } ]

    mock_execute_request(expected_result)

    assert_equal expected_result[0], relation[0].to_h
    assert_equal expected_result[1], relation[1].to_h
  end
end
