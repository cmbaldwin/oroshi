# frozen_string_literal: true

# CRITICAL: Load Solid gems BEFORE Rails.application.configure
# These must be required first to ensure Railties register properly
require "solid_queue"
require "solid_cache"
require "solid_cable"

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
        app.config.assets.precompile += %w[
          oroshi/application.css
          oroshi/application.js
        ]
      end
    end
  end
end
