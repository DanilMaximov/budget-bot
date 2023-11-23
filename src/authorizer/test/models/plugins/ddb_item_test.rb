# frozen_string_literal: true

require "test_helper"
require "ostruct"
require_relative "../../../models/plugins/ddb_item"

describe Plugins::DynamoDB::Item do
  let(:model) { Model.define(:name) { include Plugins::DynamoDB::Item } }
  let(:stub_ddb_client) { Aws::DynamoDB::Client.new(stub_responses: true) }
  let(:table_name) { "test" }

  before do
    model.stubs(:table_name).returns(table_name)
    model.stubs(:connection).returns(stub_ddb_client)
  end

  describe "query" do
    let(:exppected_query) { "" }
    let(:expected_params) { {} }

    before do
      stub_ddb_client.expects(:execute_statement).with(statement: exppected_query, **expected_params)
        .returns(OpenStruct.new(items: [ { name: "Pupa" } ]))
    end

    describe "#where" do
      let(:exppected_query) { "SELECT * FROM #{table_name}\nWHERE name = 'Pupa'\n" }

      it "generates the expected WHERE clause string for a basic query" do
        model.where(name: "Pupa")
      end

      describe "with filters" do
        let(:exppected_query) { "SELECT * FROM #{table_name}\nWHERE name = 'Pupa'\nORDER BY name DESC\n" }
        let(:expected_params) { { limit: 1 } }

        it "generates the expected WHERE clause string for a basic query" do
          model.where(name: "Pupa", order_by: [ :name, :desc ], limit: 1)
        end
      end

      describe "with multiple conditions" do
        let(:exppected_query) { "SELECT * FROM #{table_name}\nWHERE name = 'Pupa' AND age = 1\n" }

        it "generates the expected WHERE clause string for a basic query" do
          model.where(name: "Pupa", age: 1)
        end
      end
    end

    describe "#find_by" do
      let(:exppected_query) { "SELECT * FROM #{table_name}\nWHERE name = 'Pupa'\n" }
      let(:expected_params) { { limit: 1 } }

      it "generates the expected WHERE clause string for a basic query" do
        model.find_by(name: "Pupa")
      end
    end

    describe "#update" do
      let(:exppected_query) { "UPDATE #{table_name}\nSET name = 'Pupa'\nALL NEW *" }

      it "generates the expected SET clause string for a basic query" do
        model.update(name: "Pupa")
      end

      describe "with filters" do
        let(:exppected_query) { "UPDATE #{table_name}\nSET name = 'Pupa'\nORDER BY name DESC\nALL NEW *" }
        let(:expected_params) { { limit: 1 } }

        it "generates the expected SET clause string for a basic query" do
          model.update(name: "Pupa", order_by: [ :name, :desc ], limit: 1)
        end
      end
    end

    describe "#delete" do
      let(:exppected_query) { "DELETE FROM #{table_name}\nWHERE name = 'Pupa'\n" }

      it "generates the expected WHERE clause string for a basic query" do
        model.delete(name: "Pupa")
      end

      describe "with filters" do
        let(:exppected_query) { "DELETE FROM #{table_name}\nWHERE name = 'Pupa'\nORDER BY name DESC\n" }
        let(:expected_params) { { limit: 1 } }

        it "generates the expected WHERE clause string for a basic query" do
          model.delete(name: "Pupa", order_by: [ :name, :desc ], limit: 1)
        end
      end
    end

    describe "#create" do
      let(:exppected_query) { "INSERT INTO #{table_name}\nVALUES {name: 'Pupa'}\n" }

      it "generates the expected VALUES clause string for a basic query" do
        model.create(name: "Pupa")
      end
    end
  end

  describe "result" do
    let(:ddb_response) { { items: [ { "name" => "Pupa" } ] } }

    before do
      stub_ddb_client.stub_responses(:execute_statement, ddb_response)
    end

    it "return instance of model when single item returned" do
      model.find_by(name: "Pupa") do |result|
        assert_equal result.name, "Pupa"
      end
    end

    describe "when several items are returned" do
      let(:ddb_response) { { items: [ { "name" => "Pupa" }, { "name" => "Lupa" } ] } }

      it "creates collection of new instances of the model if the query returns multiple results" do
        model.where(name: "Pupa") do |result|
          assert_equal result[0].name, "Pupa"
          assert_equal result[1].name, "Lupa"
        end
      end
    end

    describe "when no items are returned" do
      let(:ddb_response) { { items: [] } }

      it "returns nil if the query returns no results" do
        model.where(name: "Pupa") do |result|
          assert_nil result
        end
      end
    end
  end
end
