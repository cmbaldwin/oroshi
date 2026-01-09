# frozen_string_literal: true

namespace :data do
  desc "Migrate User data column from YAML to JSON format"
  task migrate_user_data_to_json: :environment do
    puts "Migrating User data from YAML to JSON..."
    puts "Total users to check: #{User.count}"
    puts ""

    migrated_count = 0
    error_count = 0
    skipped_count = 0

    # Collect all user data by reading raw database values (unencrypted YAML)
    user_data_map = {}

    User.find_each do |user|
      begin
        # Read the raw value from database (before type casting/encryption)
        raw_value = user.read_attribute_before_type_cast(:data)

        if raw_value.blank?
          skipped_count += 1
          next
        end

        # Parse the YAML directly (data is currently unencrypted YAML in DB)
        if raw_value.is_a?(String) && raw_value.start_with?("---")
          data = YAML.safe_load(raw_value, permitted_classes: [ Symbol, Date, Time, ActiveSupport::TimeWithZone ], aliases: true)
          user_data_map[user.id] = { email: user.email, data: data }
          puts "✓ Read YAML data for user #{user.id} (#{user.email})"
        else
          puts "- Skipped user #{user.id} - not YAML format"
          skipped_count += 1
        end
      rescue StandardError => e
        error_count += 1
        puts "✗ Error reading user #{user.id}: #{e.class} - #{e.message}"
      end
    end

    puts "\nRead #{user_data_map.count} users with YAML data"
    puts "\nNow switching to JSON serialization and writing back (will be encrypted)..."
    puts ""

    # Now change the User model to use JSON serialization
    User.class_eval do
      serialize :data, coder: JSON
    end

    # Write the data back (will now be serialized as JSON and encrypted)
    user_data_map.each do |user_id, info|
      begin
        user = User.find(user_id)
        user.data = info[:data]
        user.save!

        migrated_count += 1
        puts "✓ Migrated user #{user_id} (#{info[:email]}) to encrypted JSON"
      rescue StandardError => e
        error_count += 1
        puts "✗ Error migrating user #{user_id}: #{e.class} - #{e.message}"
      end
    end

    puts "\nMigration complete!"
    puts "Migrated: #{migrated_count}"
    puts "Skipped (no data): #{skipped_count}"
    puts "Read errors: #{error_count}"
    puts "Total users: #{User.count}"
    puts ""
    puts "IMPORTANT: Now update User model to use JSON serialization and deploy!"
  end
end
