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

      def mysql?
        adapter =~ /mysql/i
      end

      # use connection_config instead of connection.adapter
      # so database connection isn't needed
      def adapter
        if ActiveRecord::VERSION::STRING.to_f >= 6.1
          ActiveRecord::Base.connection_db_config.adapter.to_s
        else
          ActiveRecord::Base.connection_config[:adapter].to_s
        end
      end
    end
  end
end
