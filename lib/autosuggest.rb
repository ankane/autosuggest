# stdlib
require "set"
require "yaml" # for obscenity

# dependencies
require "lingua/stemmer"
require "obscenity"

# modules
require "autosuggest/processor"
require "autosuggest/version"

module Autosuggest
  def self.new(*args, **options)
    Processor.new(*args, **options)
  end
end
