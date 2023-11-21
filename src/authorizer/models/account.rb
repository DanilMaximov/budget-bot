# frozen_string_literal: true

require_relative "model"
require_relative "plugins/ddb_item"

class Account < Model.define(:id, :integrations)
  class Integration < Model.define(:id, :internal_id, :account_id, :name, :last_event_id, :status)
    def self.table_name = "account_integrations"

    include Plugins::DynamoDB::Item

    def busy?
      status == :busy
    end
  end
end
