# frozen_string_literal: true

source "https://rubygems.org" do
  eval_gemfile "gemfiles/rubocop.gemfile"
  eval_gemfile "gemfiles/minitest.gemfile"

  gem 'telegram-bot-ruby', '~> 1.0'

  group :test, :development do
    gem 'pry-byebug', platform: :mri
    gem "rake", ">= 13.0"
    gem 'dotenv'
    gem 'pry'
  end
end