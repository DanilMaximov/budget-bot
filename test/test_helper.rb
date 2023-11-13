# frozen_string_literal: true
require 'dotenv'

require "bundler/setup"
require "minitest/autorun"
require 'mocha/minitest'
require "minitest/reporters"

Dotenv.load(".env.test") 

Dir["./src/**/*.rb"].each { |file| require file }

Minitest::Reporters.use! [ Minitest::Reporters::SpecReporter.new(color: true) ]
