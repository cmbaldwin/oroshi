# frozen_string_literal: true

require "rails/generators"
require "rails/generators/active_record"

module Oroshi
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      class_option :skip_migrations, type: :boolean, default: false,
                   desc: "Skip copying migrations"
      class_option :skip_devise, type: :boolean, default: false,
                   desc: "Skip Devise setup (if already configured)"
      class_option :skip_user_model, type: :boolean, default: false,
                   desc: "Skip User model generation (if already exists)"

      def welcome
        say "Installing Oroshi Engine...", :green
        say ""
      end

      def check_dependencies
        return if defined?(Devise)

        say "WARNING: Devise is required but not found.", :yellow
        say "Please add 'gem \"devise\"' to your Gemfile and run 'bundle install'", :yellow
        say ""
      end

      def create_initializer
        say "Creating Oroshi initializer...", :green
        template "initializer.rb", "config/initializers/oroshi.rb"
      end

      def create_user_model
        return if options[:skip_user_model]
        return if File.exist?("app/models/user.rb")

        say "Creating User model...", :green
        template "user_model.rb", "app/models/user.rb"
      end

      def setup_devise
        return if options[:skip_devise]

        if defined?(Devise)
          say "Setting up Devise...", :green

          # Check if devise routes already exist
          unless File.read("config/routes.rb").include?("devise_for :users")
            route 'devise_for :users, controllers: { sessions: "users/sessions", registrations: "users/registrations" }'
          end

          # Create Devise configuration if it doesn't exist
          unless File.exist?("config/initializers/devise.rb")
            say "Run 'rails generate devise:install' to configure Devise", :yellow
          end
        else
          say "Skipping Devise setup (not found)", :yellow
        end
      end

      def mount_engine
        say "Mounting Oroshi engine...", :green

        route_content = <<~RUBY
          # Mount Oroshi engine
          mount Oroshi::Engine, at: "/"
        RUBY

        # Check if engine is already mounted
        unless File.read("config/routes.rb").include?("Oroshi::Engine")
          route route_content
        end
      end

      def copy_migrations
        return if options[:skip_migrations]

        say "Copying migrations...", :green

        # Copy Oroshi migrations
        rake "oroshi:install:migrations"

        # Copy Solid Queue, Cache, Cable schemas
        copy_file "queue_schema.rb", "db/queue_schema.rb"
        copy_file "cache_schema.rb", "db/cache_schema.rb"
        copy_file "cable_schema.rb", "db/cable_schema.rb"
      end

      def create_database_config
        say "Updating database configuration...", :green

        if File.exist?("config/database.yml")
          say "NOTE: You need to manually configure multiple databases in config/database.yml", :yellow
          say "See sandbox/config/database.yml for an example", :yellow
        else
          template "database.yml", "config/database.yml"
        end
      end

      def show_post_install_instructions
        say ""
        say "=" * 80, :green
        say "Oroshi Engine installed successfully!", :green
        say "=" * 80, :green
        say ""
        say "Next steps:", :cyan
        say ""
        say "1. Configure database.yml for multi-database setup", :cyan
        say "   (See sandbox/config/database.yml for reference)"
        say ""
        say "2. Run migrations:", :cyan
        say "   bin/rails db:create db:migrate"
        say ""
        say "3. Load Solid schemas:", :cyan
        say "   bin/rails db:schema:load:queue"
        say "   bin/rails db:schema:load:cache"
        say "   bin/rails db:schema:load:cable"
        say ""
        say "4. (Optional) Seed demo data:", :cyan
        say "   bin/rails db:seed"
        say ""
        say "5. Start the server:", :cyan
        say "   bin/rails server"
        say ""
        say "6. Visit http://localhost:3000 and sign in!", :cyan
        say ""
        say "For more information, see:", :cyan
        say "  - README.md - Main documentation"
        say "  - sandbox/README.md - Integration example"
        say "  - CLAUDE.md - Production deployment guide"
        say ""
        say "=" * 80, :green
      end
    end
  end
end
