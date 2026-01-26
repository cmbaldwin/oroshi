# frozen_string_literal: true

# =============================================================================
# OROSHI INSTALL GENERATOR
# =============================================================================
#
# This generator sets up Oroshi in a new or existing Rails application.
# It handles all the configuration needed to get Oroshi running:
#
# USAGE:
#   rails generate oroshi:install           # Full installation
#   rails generate oroshi:install --skip-migrations
#   rails generate oroshi:install --skip-devise
#   rails generate oroshi:install --skip-user-model
#   rails generate oroshi:install --run-migrations  # Also runs db:migrate
#
# WHAT THIS GENERATOR DOES:
#
# 1. Creates config/initializers/oroshi.rb
#    - Configures timezone (Asia/Tokyo by default)
#    - Configures locale (Japanese by default)
#    - Sets domain for URL generation
#
# 2. Creates app/models/user.rb (unless --skip-user-model)
#    - Devise-based authentication model
#    - Role-based access (user, vip, admin, supplier, employee)
#
# 3. Configures Devise routes (unless --skip-devise)
#    - Adds devise_for :users to config/routes.rb
#    - Checks for existing Devise configuration
#
# 4. Mounts Oroshi engine at "/"
#    - Adds mount Oroshi::Engine, at: "/" to config/routes.rb
#    - Safe to run multiple times (won't duplicate)
#
# 5. Adds root route for main_app.root_path
#    - Required because engine views reference main_app.root_path
#
# 6. Copies migrations (unless --skip-migrations)
#    - Copies all Oroshi migrations to db/migrate/
#    - Copies Solid Queue/Cache/Cable schemas to db/
#
# 7. Optionally runs db:migrate (with --run-migrations flag)
#
# PREREQUISITES:
#   - Rails 8.0+ application
#   - PostgreSQL database (for multi-database support)
#   - Devise gem in Gemfile (or --skip-devise)
#
# AFTER INSTALLATION:
#   1. Configure database.yml for multi-database setup
#   2. Run: bin/rails db:create db:migrate
#   3. Run: bin/rails db:schema:load:queue
#   4. Run: bin/rails db:schema:load:cache
#   5. Run: bin/rails db:schema:load:cable
#   6. Start server: bin/rails server
#
# SEE ALSO:
#   - README.md for full documentation
#   - CLAUDE.md for production deployment guide
#   - sandbox/ for a complete working example
#
# =============================================================================

require "rails/generators"
require "rails/generators/active_record"

module Oroshi
  module Generators
    # InstallGenerator sets up Oroshi in a Rails application.
    #
    # This generator is idempotent - it can be run multiple times safely.
    # Existing files are not overwritten unless explicitly confirmed.
    #
    # @example Install with all defaults
    #   rails generate oroshi:install
    #
    # @example Install without running migrations
    #   rails generate oroshi:install --skip-migrations
    #
    # @example Install and run migrations automatically
    #   rails generate oroshi:install --run-migrations
    #
    class InstallGenerator < Rails::Generators::Base
      include ActiveRecord::Generators::Migration

      source_root File.expand_path("templates", __dir__)

      # Command-line options
      class_option :skip_migrations, type: :boolean, default: false,
                   desc: "Skip copying migrations"
      class_option :skip_devise, type: :boolean, default: false,
                   desc: "Skip Devise setup (if already configured)"
      class_option :skip_user_model, type: :boolean, default: false,
                   desc: "Skip User model generation (if already exists)"
      class_option :run_migrations, type: :boolean, default: false,
                   desc: "Run db:migrate after copying migrations"

      # Step 1: Display welcome message
      def welcome
        say "Installing Oroshi Engine...", :green
        say ""
      end

      # Step 2: Check that Devise gem is available
      # Warns if Devise is not found - installation can continue but
      # authentication will need to be configured manually
      def check_dependencies
        return if defined?(Devise)

        say "WARNING: Devise is required but not found.", :yellow
        say "Please add 'gem \"devise\"' to your Gemfile and run 'bundle install'", :yellow
        say ""
      end

      # Step 3: Create Oroshi initializer
      # Creates config/initializers/oroshi.rb with default configuration
      def create_initializer
        say "Creating Oroshi initializer...", :green
        template "initializer.rb", "config/initializers/oroshi.rb"
      end

      # Step 4: Create User model for Devise authentication
      # Skipped if --skip-user-model or if app/models/user.rb already exists
      def create_user_model
        return if options[:skip_user_model]
        return if File.exist?("app/models/user.rb")

        say "Creating User model...", :green
        template "user_model.rb", "app/models/user.rb"
      end

      # Step 5: Configure Devise routes
      # Adds devise_for :users to config/routes.rb if not already present
      # Skipped if --skip-devise or if Devise is not installed
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

      # Step 6: Mount Oroshi engine in routes.rb
      # Adds mount Oroshi::Engine, at: "/" to config/routes.rb
      # Safe to run multiple times - checks for existing mount
      def mount_engine
        say "Mounting Oroshi engine...", :green

        route_content = <<~RUBY
          # Mount Oroshi engine
          # Change "/" to "/oroshi" if you want the engine at a different path
          mount Oroshi::Engine, at: "/"
        RUBY

        # Check if engine is already mounted
        unless File.read("config/routes.rb").include?("Oroshi::Engine")
          route route_content
        end
      end

      # Step 7: Add required root route for main_app.root_path
      # Oroshi engine uses main_app.root_path, so parent app needs a root route
      def add_root_route
        routes_content = File.read("config/routes.rb")
        return if routes_content.include?("root ")
        return if routes_content.include?("root\"")
        return if routes_content.include?("root'")

        say "Adding root route (required for main_app.root_path)...", :green
        route 'root "oroshi/dashboard#index"'
      end

      # Step 8: Copy migrations and Solid schemas
      # Copies all Oroshi migrations and Solid Queue/Cache/Cable schemas
      # Skipped if --skip-migrations
      def copy_migrations
        return if options[:skip_migrations]

        say "Copying migrations...", :green

        # Copy Oroshi migrations using rake task
        rake "oroshi:install:migrations"

        # Copy Solid Queue, Cache, Cable schemas
        # These are loaded separately from main migrations
        copy_file "queue_schema.rb", "db/queue_schema.rb"
        copy_file "cache_schema.rb", "db/cache_schema.rb"
        copy_file "cable_schema.rb", "db/cable_schema.rb"
      end

      # Step 9: Run database migrations (optional)
      # Only runs if --run-migrations flag is passed
      def run_migrations
        return unless options[:run_migrations]

        say "Running database migrations...", :green
        rake "db:migrate"

        say "Loading Solid schemas...", :green
        rake "db:schema:load:queue"
        rake "db:schema:load:cache"
        rake "db:schema:load:cable"
      end

      # Step 10: Show database configuration notes
      # Reminds user to configure multi-database setup
      def create_database_config
        say "Updating database configuration...", :green

        if File.exist?("config/database.yml")
          say "NOTE: You need to manually configure multiple databases in config/database.yml", :yellow
          say "See sandbox/config/database.yml for an example", :yellow
        else
          template "database.yml", "config/database.yml"
        end
      end

      # Step 11: Display post-installation instructions
      # Shows all remaining steps needed to complete installation
      def show_post_install_instructions
        say ""
        say "=" * 80, :green
        say "Oroshi Engine installed successfully!", :green
        say "=" * 80, :green
        say ""
        say "Next steps:", :cyan
        say ""

        if options[:run_migrations]
          say "Migrations have been run automatically.", :green
          say ""
        else
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
        end

        say "Start the server:", :cyan
        say "   bin/rails server"
        say ""
        say "Visit http://localhost:3000 and sign in!", :cyan
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
