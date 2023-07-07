# frozen_string_literal: true

require "./lib/pupa_orm/model"
require "aws-sdk-dynamodb"

DB ||= Aws::DynamoDB::Resource.new(client: Aws::DynamoDB::Client.new) # rubocop:disable Lint/OrAssignmentToConstant

class BaseModel < PupaORM::Model
end
