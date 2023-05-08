# frozen_string_literal: true

require_relative "base_function"
require_relative "../interactors/add_expense"

class ExpensesFunction < Base
  MSG_REGEXP = /^((\s?)(\w+|[А-Яа-я]))* \d+ \w+$/

  def add
    authorize! @message[:chat]

    new_expense = AddExpense.call(text: @message[:text])

    if new_expense.success?
      render json: { text: "Expense added" }
    else
      render json: { errors: new_expense.error }
    end
  end
end
