# frozen_string_literal: true

require "test_helper"

describe BudgetBot do
  it "application must be defined" do
    assert_kind_of Class, BudgetBot::Application
    assert_kind_of Method, BudgetBot::Application.method(:start)
  end
end
