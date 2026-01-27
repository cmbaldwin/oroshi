# frozen_string_literal: true

require_relative "lib/oroshi/version"

Gem::Specification.new do |spec|
  spec.name        = "oroshi"
  spec.version     = Oroshi::VERSION
  spec.authors     = [ "Cody Baldwin" ]
  spec.email       = [ "cody@example.com" ]
  spec.homepage    = "https://github.com/cmbaldwin/oroshi"
  spec.summary     = "Wholesale order management system for Rails"
  spec.description = "Oroshi is an opinionated Rails engine for managing wholesale orders, inventory, suppliers, and invoicing with Japanese localization."
  spec.license     = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/cmbaldwin/oroshi"
  spec.metadata["changelog_uri"] = "https://github.com/cmbaldwin/oroshi/blob/master/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"].reject do |f|
      # Exclude standalone app routes - engine uses proper config/routes.rb
      f == "config/routes_standalone_app.rb" ||
      f == "config/routes.rb.engine" ||
      f == "config/routes_oroshi_engine.rb"
    end
  end

  spec.required_ruby_version = ">= 3.4.0"

  # Rails
  spec.add_dependency "rails", "~> 8.1"

  # Solid gems (for background jobs, cache, cable)
  spec.add_dependency "solid_queue", "~> 1.0"
  spec.add_dependency "solid_cache", "~> 1.0"
  spec.add_dependency "solid_cable", "~> 3.0"

  # Authentication & Authorization
  spec.add_dependency "devise", "~> 4.9"
  spec.add_dependency "pundit", "~> 2.4"

  # Database
  spec.add_dependency "pg", "~> 1.1"

  # Assets & Frontend
  spec.add_dependency "propshaft", "~> 1.0"
  spec.add_dependency "importmap-rails", "~> 2.0"
  spec.add_dependency "turbo-rails", "~> 2.0"
  spec.add_dependency "stimulus-rails", "~> 1.3"
  spec.add_dependency "dartsass-rails", "~> 0.5"
  spec.add_dependency "bootstrap", "~> 5.3"

  # Forms & UI
  spec.add_dependency "will_paginate", "~> 4.0"

  # Search & Filtering
  spec.add_dependency "ransack", "~> 4.2"
  spec.add_dependency "order_query", "~> 0.5"

  # PDF Generation
  spec.add_dependency "prawn", "2.4.0"
  spec.add_dependency "prawn-table", "~> 0.2"
  spec.add_dependency "combine_pdf", "~> 1.0"
  spec.add_dependency "ttfunk", "1.7.0"
  spec.add_dependency "matrix", "~> 0.4"

  # File handling
  spec.add_dependency "file_validators", "~> 3.0"

  # Localization & Data
  spec.add_dependency "carmen", "~> 1.1"
  spec.add_dependency "holiday_jp", "~> 0.8"
  spec.add_dependency "rails-i18n", "~> 8.0"

  # Email
  spec.add_dependency "resend", "~> 0.9"

  # Other utilities
  spec.add_dependency "ancestry", "~> 4.3"
  spec.add_dependency "httparty", "~> 0.22"
  spec.add_dependency "thruster", "~> 0.1"
end
