# frozen_string_literal: true

module PupaORMHelper
  def mock_execute_request(response)
    PupaORM::Connection.adapter.expects(:execute_request).at_least_once.returns(response)
  end
end
