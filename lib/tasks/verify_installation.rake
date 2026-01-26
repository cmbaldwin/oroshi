# frozen_string_literal: true

namespace :oroshi do
  desc "Verify Oroshi installation and configuration"
  task verify_installation: :environment do
    puts "\n" + "=" * 80
    puts "Oroshi Installation Verification"
    puts "=" * 80 + "\n"

    all_checks_passed = true
    checks = []

    # Check 1: Engine routes mounted
    print "1. Checking if Oroshi::Engine is mounted... "
    begin
      # Check if engine routes are accessible via main app
      engine_mounted = Rails.application.routes.routes.any? do |route|
        route.app.respond_to?(:app) && route.app.app.is_a?(Oroshi::Engine.class)
      end

      if engine_mounted
        puts "✓ PASS"
        checks << { name: "Engine mounted", status: :pass, details: nil }
      else
        puts "✗ FAIL"
        puts "   → Oroshi::Engine is not mounted in config/routes.rb"
        puts "   → Add: mount Oroshi::Engine, at: '/oroshi'"
        checks << { name: "Engine mounted", status: :fail, details: "Engine not mounted in routes" }
        all_checks_passed = false
      end
    rescue StandardError => e
      puts "✗ ERROR"
      puts "   → #{e.message}"
      checks << { name: "Engine mounted", status: :error, details: e.message }
      all_checks_passed = false
    end

    # Check 2: Initializer exists
    print "2. Checking for Oroshi initializer... "
    initializer_path = Rails.root.join("config/initializers/oroshi.rb")
    if File.exist?(initializer_path)
      puts "✓ PASS"
      checks << { name: "Initializer", status: :pass, details: nil }
    else
      puts "✗ FAIL"
      puts "   → Missing config/initializers/oroshi.rb"
      puts "   → Run: rails generate oroshi:install"
      checks << { name: "Initializer", status: :fail, details: "Missing initializer file" }
      all_checks_passed = false
    end

    # Check 3: Root route defined
    print "3. Checking for root route... "
    begin
      root_route_defined = Rails.application.routes.routes.any? do |route|
        route.name == "root"
      end

      if root_route_defined
        puts "✓ PASS"
        checks << { name: "Root route", status: :pass, details: nil }
      else
        puts "⚠ WARNING"
        puts "   → No root route defined in config/routes.rb"
        puts "   → Oroshi views may fail when using main_app.root_path"
        puts "   → Add: root to: 'welcome#index' (or your preferred controller)"
        checks << { name: "Root route", status: :warn, details: "No root route found" }
      end
    rescue StandardError => e
      puts "✗ ERROR"
      puts "   → #{e.message}"
      checks << { name: "Root route", status: :error, details: e.message }
    end

    # Check 4: Database configuration
    print "4. Checking database configuration... "
    begin
      required_databases = %w[primary queue cache cable]
      configured_databases = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env).map(&:name)

      missing_databases = required_databases - configured_databases

      if missing_databases.empty?
        puts "✓ PASS"
        checks << { name: "Database config", status: :pass, details: nil }
      else
        puts "✗ FAIL"
        puts "   → Missing database configurations: #{missing_databases.join(', ')}"
        puts "   → Ensure config/database.yml defines: primary, queue, cache, cable"
        checks << {
          name: "Database config",
          status: :fail,
          details: "Missing: #{missing_databases.join(', ')}"
        }
        all_checks_passed = false
      end
    rescue StandardError => e
      puts "✗ ERROR"
      puts "   → #{e.message}"
      checks << { name: "Database config", status: :error, details: e.message }
      all_checks_passed = false
    end

    # Check 5: Primary database tables
    print "5. Checking primary database migrations... "
    begin
      # Connect to primary database
      ActiveRecord::Base.connection_pool.with_connection do |conn|
        # Check for oroshi_ prefixed tables as indicator migrations ran
        # Try oroshi_buyers as a core table that should always exist
        if conn.table_exists?(:oroshi_buyers)
          puts "✓ PASS"
          checks << { name: "Primary migrations", status: :pass, details: nil }
        else
          puts "✗ FAIL"
          puts "   → Oroshi tables not found (e.g., oroshi_buyers)"
          puts "   → Run: rails db:migrate"
          checks << { name: "Primary migrations", status: :fail, details: "Tables not created" }
          all_checks_passed = false
        end
      end
    rescue StandardError => e
      puts "✗ ERROR"
      puts "   → #{e.message}"
      puts "   → Run: rails db:create db:migrate"
      checks << { name: "Primary migrations", status: :error, details: e.message }
      all_checks_passed = false
    end

    # Check 6: Queue database
    print "6. Checking Solid Queue database... "
    begin
      # Get the queue database configuration
      queue_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "queue")

      if queue_config
        # Establish a direct connection to check tables
        ActiveRecord::Base.establish_connection(queue_config.configuration_hash)
        queue_connection = ActiveRecord::Base.connection

        if queue_connection.table_exists?(:solid_queue_jobs)
          puts "✓ PASS"
          checks << { name: "Queue database", status: :pass, details: nil }
        else
          puts "✗ FAIL"
          puts "   → Solid Queue tables not found"
          puts "   → Run: rails db:schema:load:queue"
          checks << { name: "Queue database", status: :fail, details: "Queue tables not created" }
          all_checks_passed = false
        end

        # Restore primary connection
        ActiveRecord::Base.establish_connection(:primary)
      else
        puts "✗ FAIL"
        puts "   → Queue database not configured in config/database.yml"
        checks << { name: "Queue database", status: :fail, details: "Configuration missing" }
        all_checks_passed = false
      end
    rescue StandardError => e
      puts "✗ ERROR"
      puts "   → #{e.message}"
      puts "   → Ensure queue database exists and schema loaded"
      checks << { name: "Queue database", status: :error, details: e.message }
      all_checks_passed = false
      # Ensure we restore primary connection even on error
      ActiveRecord::Base.establish_connection(:primary) rescue nil
    end

    # Check 7: Cache database
    print "7. Checking Solid Cache database... "
    begin
      cache_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "cache")

      if cache_config
        ActiveRecord::Base.establish_connection(cache_config.configuration_hash)
        cache_connection = ActiveRecord::Base.connection

        if cache_connection.table_exists?(:solid_cache_entries)
          puts "✓ PASS"
          checks << { name: "Cache database", status: :pass, details: nil }
        else
          puts "✗ FAIL"
          puts "   → Solid Cache tables not found"
          puts "   → Run: rails db:schema:load:cache"
          checks << { name: "Cache database", status: :fail, details: "Cache tables not created" }
          all_checks_passed = false
        end

        ActiveRecord::Base.establish_connection(:primary)
      else
        puts "✗ FAIL"
        puts "   → Cache database not configured in config/database.yml"
        checks << { name: "Cache database", status: :fail, details: "Configuration missing" }
        all_checks_passed = false
      end
    rescue StandardError => e
      puts "✗ ERROR"
      puts "   → #{e.message}"
      puts "   → Ensure cache database exists and schema loaded"
      checks << { name: "Cache database", status: :error, details: e.message }
      all_checks_passed = false
      ActiveRecord::Base.establish_connection(:primary) rescue nil
    end

    # Check 8: Cable database
    print "8. Checking Solid Cable database... "
    begin
      cable_config = ActiveRecord::Base.configurations.configs_for(env_name: Rails.env, name: "cable")

      if cable_config
        ActiveRecord::Base.establish_connection(cable_config.configuration_hash)
        cable_connection = ActiveRecord::Base.connection

        if cable_connection.table_exists?(:solid_cable_messages)
          puts "✓ PASS"
          checks << { name: "Cable database", status: :pass, details: nil }
        else
          puts "✗ FAIL"
          puts "   → Solid Cable tables not found"
          puts "   → Run: rails db:schema:load:cable"
          checks << { name: "Cable database", status: :fail, details: "Cable tables not created" }
          all_checks_passed = false
        end

        ActiveRecord::Base.establish_connection(:primary)
      else
        puts "✗ FAIL"
        puts "   → Cable database not configured in config/database.yml"
        checks << { name: "Cable database", status: :fail, details: "Configuration missing" }
        all_checks_passed = false
      end
    rescue StandardError => e
      puts "✗ ERROR"
      puts "   → #{e.message}"
      puts "   → Ensure cable database exists and schema loaded"
      checks << { name: "Cable database", status: :error, details: e.message }
      all_checks_passed = false
      ActiveRecord::Base.establish_connection(:primary) rescue nil
    end

    # Check 9: User model
    print "9. Checking User model... "
    begin
      if defined?(User) && User.respond_to?(:new)
        # Check if User has required Oroshi methods/associations
        user_instance = User.new
        if user_instance.respond_to?(:buyer) && user_instance.respond_to?(:role)
          puts "✓ PASS"
          checks << { name: "User model", status: :pass, details: nil }
        else
          puts "⚠ WARNING"
          puts "   → User model exists but may be missing Oroshi associations"
          puts "   → Ensure User has: belongs_to :buyer and enum :role"
          checks << { name: "User model", status: :warn, details: "Missing Oroshi associations" }
        end
      else
        puts "✗ FAIL"
        puts "   → User model not found"
        puts "   → Run: rails generate oroshi:install"
        checks << { name: "User model", status: :fail, details: "User model not defined" }
        all_checks_passed = false
      end
    rescue StandardError => e
      puts "✗ ERROR"
      puts "   → #{e.message}"
      checks << { name: "User model", status: :error, details: e.message }
      all_checks_passed = false
    end

    # Summary
    puts "\n" + "=" * 80
    puts "Summary"
    puts "=" * 80

    pass_count = checks.count { |c| c[:status] == :pass }
    fail_count = checks.count { |c| c[:status] == :fail }
    warn_count = checks.count { |c| c[:status] == :warn }
    error_count = checks.count { |c| c[:status] == :error }

    puts "\nTotal Checks: #{checks.length}"
    puts "✓ Passed: #{pass_count}"
    puts "✗ Failed: #{fail_count}" if fail_count.positive?
    puts "⚠ Warnings: #{warn_count}" if warn_count.positive?
    puts "✗ Errors: #{error_count}" if error_count.positive?

    if all_checks_passed && warn_count.zero?
      puts "\n🎉 All checks passed! Oroshi is properly installed and configured."
      puts "\nNext steps:"
      puts "  1. Start the development server: ./bin/dev"
      puts "  2. Visit http://localhost:3000/oroshi"
      puts "  3. Sign in or create an admin account"
      exit 0
    elsif all_checks_passed
      puts "\n✓ Installation looks good, but there are some warnings to review."
      exit 0
    else
      puts "\n✗ Installation verification failed. Please fix the issues above."
      puts "\nFor help, see: README.md (Troubleshooting section)"
      exit 1
    end
  end
end
