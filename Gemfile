# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "4.0.0"

# Environment configuration
gem "dotenv-rails", groups: %i[development test] # Load environment variables from .env files

# Rails 8 solid libraries for modern infrastructure
gem "solid_cable"  # Database-backed Action Cable adapter
gem "solid_cache"  # Database-backed Rails cache store
gem "solid_queue"  # Database-backed Active Job adapter

# Deployment and infrastructure
gem "kamal"     # Zero-downtime deployments with Docker
gem "propshaft" # Modern asset pipeline for Rails
gem "rails"     # Ruby on Rails framework
gem "rake"      # Ruby build tool
gem "thruster"  # HTTP/2 proxy for Rails applications

# Frontend framework and assets
gem "bootstrap", "~> 5"             # Bootstrap CSS framework
gem "dartsass-rails"                # Dart Sass processor for Rails
gem "importmap-rails"               # JavaScript import maps
gem "rack-cache"                    # HTTP caching middleware
gem "stimulus-rails"                # Hotwire Stimulus framework
gem "turbo-rails", github: "hotwired/turbo-rails" # Hotwire Turbo framework

# Database and server
gem "pg"   # PostgreSQL adapter
gem "puma" # Ruby web server

# Email protocols (optional requires)
gem "net-imap", require: false
gem "net-pop", require: false
gem "net-smtp", require: false

# Utilities
gem "statistics" # Statistical calculations

# JSON builder
gem "jbuilder", "~> 2.5"

# Core utilities
gem "bcrypt", "~> 3.1.7"              # Password hashing
gem "bootsnap", ">= 1.1.0", require: false # Boot time optimization
gem "awesome_print"                   # Pretty print Ruby objects
gem "carmen"                          # Country and region data
gem "rails-i18n"                      # Rails internationalization

# Development and testing tools
group :development, :test do
  gem "byebug"                       # Ruby debugger
  gem "listen"                       # File modification listener
  gem "rack-cors"                    # Cross-Origin Resource Sharing
  gem "rails-erd"                    # Entity-Relationship diagram generator
  gem "rails-controller-testing"    # Controller testing helpers
  gem "rubocop-rails-omakase", require: false # Ruby style guide and linter
  gem "brakeman", require: false    # Security vulnerability scanner
  gem "seed_dump"                   # Database seed file generator
end

# Development-only tools
group :development do
  gem "bullet"                       # N+1 query detector
  gem "iconv", "~> 1.1"             # Character encoding conversion
  gem "mailcatcher"                 # Email testing tool
  gem "web-console"                 # Interactive debugging console
end

# Testing tools
group :test do
  gem "capybara"                     # Integration testing framework
  gem "capybara-lockstep"           # Synchronization for Capybara tests
  gem "factory_bot_rails"           # Test data factories
  gem "faker"                       # Fake data generator
  gem "ffaker"                      # Fast fake data generator
  gem "minitest", "< 6.0"           # Testing framework
  gem "parallel_tests"              # Parallel test execution
  gem "selenium-webdriver"          # Browser automation for system tests
  gem "webmock"                     # HTTP request stubbing
end

# Authentication and authorization
gem "devise", ">= 4.7.1" # User authentication solution
gem "pundit", "~> 2.4"   # Object-oriented authorization

# File handling
gem "file_validators"                # File upload validation

# Data organization
gem "ancestry"     # Tree structure for hierarchical data

# Email
gem "resend" # Email delivery service

# Pagination
gem "will_paginate" # Pagination library

# PDF generation
gem "combine_pdf"  # Merge and manipulate PDF files
gem "matrix"       # Matrix operations (required for prawn)
gem "prawn", "2.4.0"      # PDF generation
gem "prawn-table"  # Table support for prawn
gem "ttfunk", "1.7.0"     # TrueType font parsing (prawn dependency)

# API and integrations
gem "httparty" # HTTP client for API calls

# Date utilities
gem "holiday_jp" # Japanese holiday calendar

# Query optimization
gem "order_query" # Efficient keyset pagination

# Search and filtering
gem "ransack" # Object-based searching
