# frozen_string_literal: true

require "bundler/setup"

require "minitest/autorun"
require "minitest/reporters"

Dir["./test/support/**/*.rb"].each { |file| require file }
Dir["./src/**/*.rb", "./lib/**/*.rb"].each { |file| require file }

Minitest::Reporters.use! [ Minitest::Reporters::SpecReporter.new(color: true) ]
