# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  # fixtures :all

  # Use transactional tests (rollback after each test)
  self.use_transactional_tests = true

  # Include FactoryBot methods
  include FactoryBot::Syntax::Methods

  # Set locale to Japanese for all tests
  setup do
    I18n.locale = :ja
  end

  # Add more helper methods to be used by all tests here...
end

# Configure FactoryBot to load from test/factories
FactoryBot.definition_file_paths = [ Rails.root.join("test/factories") ]
# find_definitions is called automatically in Rails test environment

# Configure Shoulda Matchers for Minitest (if gem is installed)
begin
  require "shoulda/matchers"

  Shoulda::Matchers.configure do |config|
    config.integrate do |with|
      with.test_framework :minitest
      with.library :rails
    end
  end
rescue LoadError
  # Shoulda matchers not installed, skipping configuration
end

# Include Devise test helpers for integration tests
class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  include Warden::Test::Helpers
end
