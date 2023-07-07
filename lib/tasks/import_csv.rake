# frozen_string_literal: true
# require "./src/clients/notion"
# require "dotenv/load"

# CATEGORY_MAP = {
#   "www.grab.com" => "Food",
#   "Mini Big C -Thanon Pat" => "Food",
#   "7-11" => "Food",
#   "Grab Rides-Ec" => "Live",
#   "Opn*trueiservicetopup" => "Live",
#   "Mcdonalds-Intermark" => "Food",
#   "La Bodega" => "Food"
# }

# desc "Backfill notion table with revolut monthly statement"
# task :backfill_revolut_statement, [:f_path] do |t, args|
#   require 'csv'

#   CSV.read(args.fetch(:f_path))
#     .filter { |r| !CATEGORY_MAP[r[4]].nil? || r[4].start_with?("7-11") }
#     .each do |row|
#       notion = Clients::Notion.new
#       notion.create_page(
#         date: Date.parse(row[2]).iso8601,
#         expense: row[4],
#         amount: ((row[5].to_i * -1) * 33.75).round(2),
#         category: CATEGORY_MAP[row[4]] || "Food"
#       )
#     end
# end
