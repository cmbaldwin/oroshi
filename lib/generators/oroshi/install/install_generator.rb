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
#    - Role-based access (user, managerial, admin, supplier, employee)
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

      # Step 1.5: Ask setup questions
      def ask_setup_questions
        say "=" * 80, :cyan
        say "Oroshi Setup Configuration", :cyan
        say "=" * 80, :cyan
        say ""

        # Ask about data seeding
        @seed_choice = ask("Would you like to seed demo data?", :cyan, limited_to: %w[yes no y n])
        @seed_demo_data = %w[yes y].include?(@seed_choice.downcase)

        say ""

        # Ask about onboarding
        if @seed_demo_data
          say "Note: Demo data includes all required records, so onboarding is not needed.", :yellow
          @enable_onboarding = false
        else
          @onboarding_choice = ask("Enable onboarding UI for initial setup?", :cyan, limited_to: %w[yes no y n])
          @enable_onboarding = %w[yes y].include?(@onboarding_choice.downcase)
        end

        say ""
        say "=" * 80, :cyan
        say ""
      end

      # Helper method for templates to get app name
      def app_name
        @app_name ||= begin
          if defined?(Rails.application)
            Rails.application.class.module_parent_name.underscore
          else
            "oroshi_app"
          end
        end
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
        return if File.exist?(File.join(destination_root, "app/models/user.rb"))

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
          routes_path = File.join(destination_root, "config/routes.rb")
          if File.exist?(routes_path)
            unless File.read(routes_path).include?("devise_for :users")
              route 'devise_for :users, controllers: { sessions: "users/sessions", registrations: "users/registrations" }'
            end
          else
            route 'devise_for :users, controllers: { sessions: "users/sessions", registrations: "users/registrations" }'
          end

          # Create Devise configuration if it doesn't exist
          unless File.exist?(File.join(destination_root, "config/initializers/devise.rb"))
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
        routes_path = File.join(destination_root, "config/routes.rb")
        unless File.read(routes_path).include?("Oroshi::Engine")
          route route_content
        end
      end

      # Step 7: Add required root route for main_app.root_path
      # Oroshi engine uses main_app.root_path, so parent app needs a root route
      def add_root_route
        routes_path = File.join(destination_root, "config/routes.rb")
        routes_content = File.read(routes_path)
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

      # Step 9.5: Create admin user
      # Prompts for admin credentials and creates the user
      def create_admin_user
        return unless options[:run_migrations]

        say ""
        say "=" * 80, :cyan
        say "Admin User Setup", :cyan
        say "=" * 80, :cyan
        say ""

        # Prompt for admin credentials
        admin_email = ask("Admin email (default: admin@#{app_name}.local):", :cyan)
        admin_email = "admin@#{app_name}.local" if admin_email.blank?

        admin_username = ask("Admin username (default: admin):", :cyan)
        admin_username = "admin" if admin_username.blank?

        admin_password = ask("Admin password (default: auto-generated):", :cyan, echo: false)
        say "" # New line after password input

        if admin_password.blank?
          admin_password = SecureRandom.hex(16)
          @generated_password = admin_password
          say "⚠️  Auto-generated password: #{admin_password}", :yellow
          say "⚠️  IMPORTANT: Save this password and change it after first login!", :yellow
        end

        say ""
        say "Creating admin user...", :green

        # Create the admin user
        begin
          # Use a rails runner to create the user
          user_creation_code = <<~RUBY
            user = User.create!(
              email: '#{admin_email}',
              username: '#{admin_username}',
              password: '#{admin_password}',
              password_confirmation: '#{admin_password}',
              role: :admin,
              approved: true,
              confirmed_at: Time.current
            )

            # Skip onboarding for admin if demo data was seeded
            if ENV['SEED_DEMO_DATA'] == 'true'
              progress = user.create_onboarding_progress!
              progress.update!(skipped_at: Time.current)
            elsif ENV['ENABLE_ONBOARDING'] == 'true'
              progress = user.create_onboarding_progress!
            end

            puts "✓ Admin user created successfully"
          RUBY

          env_vars = {}
          env_vars["SEED_DEMO_DATA"] = "true" if @seed_demo_data
          env_vars["ENABLE_ONBOARDING"] = "true" if @enable_onboarding

          # Write the code to a temp file and execute it
          require "tempfile"
          Tempfile.create(["admin_user", ".rb"]) do |f|
            f.write(user_creation_code)
            f.flush
            system(env_vars, "rails", "runner", f.path)
          end

          @admin_email = admin_email
          @admin_username = admin_username
          @admin_password_shown = @generated_password.present?

        rescue => e
          say "Error creating admin user: #{e.message}", :red
          say "You can create an admin user manually later using:", :yellow
          say "  User.create!(email: '#{admin_email}', username: '#{admin_username}', password: 'your_password', role: :admin, approved: true, confirmed_at: Time.current)"
        end

        say ""
      end

      # Step 10: Show database configuration notes
      # Reminds user to configure multi-database setup
      def create_database_config
        say "Updating database configuration...", :green

        database_yml_path = File.join(destination_root, "config/database.yml")
        if File.exist?(database_yml_path)
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

        # Show admin credentials if they were created
        if @admin_email.present?
          say "Admin User Credentials:", :cyan
          say ""
          say "  Email:    #{@admin_email}", :green
          say "  Username: #{@admin_username}", :green
          if @admin_password_shown
            say "  Password: #{@generated_password}", :yellow
            say ""
            say "  ⚠️  SECURITY WARNING:", :red
            say "  This password is auto-generated. You MUST change it after first login!", :yellow
            say "  Leaving default credentials is a serious security risk.", :yellow
          end
          say ""
          say "=" * 80, :cyan
          say ""
        end

        say "Next steps:", :cyan
        say ""

        if options[:run_migrations]
          say "Migrations have been run automatically.", :green

          # Show data seeding info
          if @seed_demo_data
            say "Demo data was seeded.", :green
          elsif @enable_onboarding
            say "Onboarding is enabled - you'll be guided through setup.", :green
          end
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
