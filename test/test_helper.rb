# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

# Use the dummy application for testing the engine
# The dummy app mimics how a real parent application would configure Oroshi:
# - Provides User model with Devise authentication
# - Mounts Oroshi::Engine at /oroshi
# - Provides devise_for :users routes
require_relative "dummy/config/environment"
require "rails/test_help"
require_relative "support/route_helpers"
require "mocha/minitest"

# Suppress Turbo broadcasts in tests (they fail with routing errors)
module Turbo
  module Broadcastable
    def broadcast_replace_to(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_append_to(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_prepend_to(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_remove_to(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_replace_later_to(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_append_later_to(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_prepend_later_to(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_remove_later_to(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_render_to(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_render_later_to(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_action_later_to(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_replace_later(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_remove(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_action_to(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_replace(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_append(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_prepend(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_refresh_later_to(*args, **kwargs)
      # No-op in tests
    end

    def broadcast_refresh_later(*args, **kwargs)
      # No-op in tests
    end
  end
end

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
# Use Oroshi::Engine.root since Rails.root points to the dummy app
FactoryBot.definition_file_paths = [ Oroshi::Engine.root.join("test/factories") ]
FactoryBot.find_definitions  # Must call manually since we changed the path after Rails loaded

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

  include OroshiRouteHelpers
end
