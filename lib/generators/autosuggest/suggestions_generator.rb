require "rails/generators/active_record"

class Autosuggest
  module Generators
    class SuggestionsGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration
      source_root File.join(__dir__, "templates")

      def copy_templates
        template "model.rb", "app/models/autosuggest/suggestion.rb"
        migration_template "migration.rb", "db/migrate/create_autosuggest_suggestions.rb", migration_version: migration_version
      end

      def migration_version
        "[#{ActiveRecord::VERSION::MAJOR}.#{ActiveRecord::VERSION::MINOR}]"
      end
    end
  end
end
