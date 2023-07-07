# frozen_string_literal: true

require_relative "base_model"

class Expense < BaseModel["expenses"]
end

# p Expense.find('1').raw_query
