# frozen_string_literal: true
# module PupaORM
#   module Helpers
#     module ModelConstructors
#       def self.included(base)
#         base.extend(ClassMethods)
#       end

#       module ClassMethods
#         def build_relation(...)
#           query = Query.build(__callee__, table_name, ...)

#           new(Relation.new(self, query)).relation
#         end

#         class << self
#           Types::Model::EQueryMethods.to_a.each do |m|
#             alias_method m, :build_relation
#           end
#         end
#       end
#     end
#   end
# end
