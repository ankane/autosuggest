require "active_record"

# for debugging
ActiveRecord::Base.logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDOUT : nil)
ActiveRecord::Migration.verbose = ENV["VERBOSE"]

# migrations
ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

ActiveRecord::Schema.define do
  create_table :autosuggest_suggestions do |t|
    t.string :query
    t.float :score
    t.datetime :updated_at
  end

  add_index :autosuggest_suggestions, :query, unique: true
end

class Autosuggest::Suggestion < ActiveRecord::Base
  self.table_name = "autosuggest_suggestions"
end
