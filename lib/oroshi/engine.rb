# frozen_string_literal: true

# CRITICAL: Load dependencies BEFORE Rails.application.configure
# These must be required first to ensure Railties register properly
require "solid_queue"
require "solid_cache"
require "solid_cable"

# Authentication & Authorization
require "devise"
require "pundit"

# Search
require "ransack"

module Oroshi
  class Engine < ::Rails::Engine
    isolate_namespace Oroshi

    config.generators do |g|
      g.test_framework :test_unit
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "test/factories"
    end

    # Configure Solid Queue
    initializer "oroshi.solid_queue" do |app|
      # Configure production queue connection
      if Rails.env.production?
        config.solid_queue.connects_to = {
          database: { writing: :queue }
        }
      end
    end

    # Configure Solid Cache
    initializer "oroshi.solid_cache" do |app|
      if Rails.env.production?
        config.solid_cache.connects_to = {
          database: { writing: :cache }
        }
      end
    end

    # Configure Solid Cable
    initializer "oroshi.solid_cable" do |app|
      if Rails.env.production?
        config.solid_cable.connects_to = {
          database: { writing: :cable }
        }
      end
    end

    # Configure autoload paths
    initializer "oroshi.autoload", before: :set_autoload_paths do |app|
      config.autoload_paths << root.join("lib")
      config.autoload_paths << root.join("lib/printables")
      config.eager_load_paths << root.join("lib")
      config.eager_load_paths << root.join("lib/printables")
    end

    # Configure i18n
    initializer "oroshi.i18n" do |app|
      config.i18n.load_path += Dir[root.join("config", "locales", "**", "*.yml")]
    end

    # Configure importmap
    initializer "oroshi.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb") if root.join("config/importmap.rb").exist?
      end
    end

    # Configure assets
    initializer "oroshi.assets" do |app|
      if app.config.respond_to?(:assets)
        # Add vendor/javascript to asset paths for importmap vendored JS files
        app.config.assets.paths << root.join("vendor/javascript")

        app.config.assets.precompile += %w[
          oroshi/application.css
          oroshi/application.js
        ]
      end
    end

    # Share engine helpers with parent application
    # This ensures helpers like `icon` are available when rendering
    # engine views from parent app controllers (e.g., Devise)
    initializer "oroshi.helpers" do
      ActiveSupport.on_load(:action_controller_base) do
        helper Oroshi::ApplicationHelper
      end
    end
  end
end
