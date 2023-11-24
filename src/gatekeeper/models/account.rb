# frozen_string_literal: true

require "./src/shared/model/model"
require "./src/shared/model/plugins/dynamodb/item"

class Account
  Session = Shared::Model.define(:id, :internal_id, :account_id, :last_event_id, :status) do
    def self.table_name = "account_integrations"

    include Plugins::DynamoDB::Item

    def busy?
      status.to_sym == :busy
    end
  end
end
