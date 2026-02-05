# frozen_string_literal: true

# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

# For engine testing, load the dummy app instead of the main app
# This prevents double initialization when running tests
if ENV["RAILS_ENV"] == "test" || ARGV.any? { |arg| arg.start_with?("test") }
  require_relative "test/dummy/config/application"
else
  require_relative "config/application"
end

Rails.application.load_tasks
