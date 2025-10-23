require "bundler/setup"
require "logger" # for Active Record < 7.1
Bundler.require(:default)
require "minitest/autorun"

require_relative "support/active_record"
