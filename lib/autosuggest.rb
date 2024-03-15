# stdlib
require "set"
require "yaml" # for obscenity

# dependencies
require "mittens"
require "obscenity"

# modules
require_relative "autosuggest/generator"
require_relative "autosuggest/version"

module Autosuggest
  def self.new(*args, **options)
    Generator.new(*args, **options)
  end
end
