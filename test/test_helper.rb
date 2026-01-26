# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

# Use the dummy application for testing the engine
# The dummy app mimics how a real parent application would configure Oroshi:
# - Provides User model with Devise authentication
# - Mounts Oroshi::Engine at /oroshi
# - Provides devise_for :users routes
require_relative "dummy/config/environment"
require "rails/test_help"

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

  # ==========================================================================
  # OROSHI ENGINE ROUTE HELPERS
  # ==========================================================================
  #
  # These methods provide convenient access to engine routes in tests.
  # Usage: oroshi.root_path, oroshi.dashboard_home_path, etc.
  #
  # Shortcut helpers are also provided: oroshi_root_path, oroshi_dashboard_home_path
  # These map directly to the engine route helpers.
  #

  # Access engine routes via Oroshi::Engine.routes.url_helpers
  def oroshi
    Oroshi::Engine.routes.url_helpers
  end

  # Shortcut route helpers - delegate to engine routes
  def oroshi_root_path(*args, **kwargs)
    oroshi.root_path(*args, **kwargs)
  end

  def oroshi_dashboard_home_path(*args, **kwargs)
    oroshi.dashboard_home_path(*args, **kwargs)
  end

  def oroshi_dashboard_suppliers_organizations_path(*args, **kwargs)
    oroshi.dashboard_suppliers_organizations_path(*args, **kwargs)
  end

  def oroshi_dashboard_supply_types_path(*args, **kwargs)
    oroshi.dashboard_supply_types_path(*args, **kwargs)
  end

  def oroshi_dashboard_shipping_path(*args, **kwargs)
    oroshi.dashboard_shipping_path(*args, **kwargs)
  end

  def oroshi_dashboard_buyers_path(*args, **kwargs)
    oroshi.dashboard_buyers_path(*args, **kwargs)
  end

  def oroshi_dashboard_materials_path(*args, **kwargs)
    oroshi.dashboard_materials_path(*args, **kwargs)
  end

  def oroshi_dashboard_products_path(*args, **kwargs)
    oroshi.dashboard_products_path(*args, **kwargs)
  end

  def oroshi_dashboard_stats_path(*args, **kwargs)
    oroshi.dashboard_stats_path(*args, **kwargs)
  end

  def oroshi_dashboard_company_path(*args, **kwargs)
    oroshi.dashboard_company_path(*args, **kwargs)
  end

  def oroshi_dashboard_company_settings_path(*args, **kwargs)
    oroshi.dashboard_company_settings_path(*args, **kwargs)
  end

  def oroshi_onboarding_index_path(*args, **kwargs)
    oroshi.onboarding_index_path(*args, **kwargs)
  end

  def oroshi_onboarding_path(*args, **kwargs)
    oroshi.onboarding_path(*args, **kwargs)
  end

  def oroshi_orders_path(*args, **kwargs)
    oroshi.orders_path(*args, **kwargs)
  end

  def oroshi_supplies_path(*args, **kwargs)
    oroshi.supplies_path(*args, **kwargs)
  end
end
