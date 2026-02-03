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

# Pagination
require "will_paginate"

# UI Components
require "ultimate_turbo_modal"

# Localization & Data
require "carmen"

module Oroshi
  class Engine < ::Rails::Engine
    isolate_namespace Oroshi

    config.generators do |g|
      g.test_framework :test_unit
      g.fixture_replacement :factory_bot
      g.factory_bot dir: "test/factories"
    end

    # Solid Queue and Solid Cache database connections are configured
    # via the parent app's database.yml (queue: and cache: entries)
    # Do NOT set connects_to here — it conflicts with database.yml multi-db config in Rails 8.1

    # Solid Cable is configured via cable.yml (no config accessor available)
    # See parent app's config/cable.yml for configuration

    # Configure autoload paths (exclude generators — they use Rails naming, not Zeitwerk)
    initializer "oroshi.autoload", before: :set_autoload_paths do |app|
      config.autoload_paths << root.join("lib")
      config.autoload_paths << root.join("lib/printables")
      config.eager_load_paths << root.join("lib")
      config.eager_load_paths << root.join("lib/printables")

      # Exclude generators and tasks from Zeitwerk autoloading
      Rails.autoloaders.main.ignore(root.join("lib/generators"))
      Rails.autoloaders.main.ignore(root.join("lib/tasks"))
    end

    # Configure i18n
    initializer "oroshi.i18n" do |app|
      config.i18n.load_path += Dir[root.join("config", "locales", "**", "*.yml")]
    end

    # Configure importmap
    initializer "oroshi.importmap", before: "importmap" do |app|
      if app.config.respond_to?(:importmap)
        app.config.importmap.paths << root.join("config/importmap.rb") if root.join("config/importmap.rb").exist?
        app.config.importmap.cache_sweepers << root.join("app/javascript") if root.join("app/javascript").exist?
      end
    end

    # Configure assets
    initializer "oroshi.assets" do |app|
      if app.config.respond_to?(:assets)
        # Add engine's JavaScript directories to asset paths
        app.config.assets.paths << root.join("app/javascript")
        app.config.assets.paths << root.join("vendor/javascript")

        app.config.assets.precompile += %w[
          application.css
          application.js
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
