# frozen_string_literal: true
require 'dotenv'
require 'json'

require "bundler/setup"
require "minitest/autorun"
require 'mocha/minitest'
require "minitest/reporters"

Dotenv.load(".env.test") 

Minitest::Reporters.use! [ Minitest::Reporters::SpecReporter.new(color: true) ]
