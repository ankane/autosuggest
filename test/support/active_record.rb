require "active_record"

# for debugging
ActiveRecord::Base.logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDOUT : nil)
ActiveRecord::Migration.verbose = ENV["VERBOSE"]

# migrations
case ENV["ADAPTER"]
when "postgresql"
  ActiveRecord::Base.establish_connection adapter: "postgresql", database: "autosuggest_test"
when "mysql"
  ActiveRecord::Base.establish_connection adapter: "mysql2", database: "autosuggest_test"
else
  ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
end

ActiveRecord::Schema.define do
  create_table :autosuggest_suggestions, force: true do |t|
    t.string :query
    t.float :score
    if ENV["ADAPTER"] == "mysql"
      t.datetime :updated_at, precision: 6
    else
      t.datetime :updated_at
    end
  end

  add_index :autosuggest_suggestions, :query, unique: true
end

class Autosuggest::Suggestion < ActiveRecord::Base
  self.table_name = "autosuggest_suggestions"
end
