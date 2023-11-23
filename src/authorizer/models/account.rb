# frozen_string_literal: true

require_relative "model"
require_relative "plugins/ddb_item"

class Account
  Session = Model.define(:id, :internal_id, :account_id, :last_event_id, :status) do
    def self.table_name = "account_integrations"

    include Plugins::DynamoDB::Item

    def busy?
      status.to_sym == :busy
    end
  end
end
