# frozen_string_literal: true

source "https://rubygems.org" do
  eval_gemfile "gemfiles/rubocop.gemfile"
  eval_gemfile "gemfiles/minitest.gemfile"
  eval_gemfile "gemfiles/dev_server.gemfile"

  # gem "interactor", "~> 3.1"
  gem "activefunction"

  group :test, :development do
    gem 'pry-byebug', platform: :mri
    gem 'dotenv'
    gem 'pry'
    gem 'ruby-next'
    gem 'aws-sdk', '~> 3', require: true
  end
end