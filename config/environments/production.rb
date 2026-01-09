# frozen_string_literal: true

# Explicitly require Solid gems to ensure Railties load before configuration
require 'solid_queue'
require 'solid_cache'
require 'solid_cable'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # Code is not reloaded between requests.
  config.cache_classes = true

  # Use Solid Cache for production caching
  config.cache_store = :solid_cache_store

  # Propshaft does not require compile configuration
  # Assets are served directly with digested filenames

  # Eager load code on boot. This eager loads most of Rails and
  # your application in memory, allowing both threaded web servers
  # and those relying on copy on write to perform better.
  # Rake tasks automatically ignore this option for performance.
  config.eager_load = true

  # Full error reports are disabled and caching is turned on.
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Ensures that a master key has been made available in either ENV["RAILS_MASTER_KEY"]
  # or in config/master.key. This key is used to decrypt credentials (and other encrypted files).
  # config.require_master_key = true

  # Disable serving static files from the `/public` folder by default since
  # Apache or NGINX already handles this.
  config.public_file_server.enabled = ENV['RAILS_SERVE_STATIC_FILES'].present?

  # Enable serving of images, stylesheets, and JavaScripts from an asset server.
  # config.action_controller.asset_host = 'http://assets.example.com'

  # Specifies the header that your server uses for sending files.
  # config.action_dispatch.x_sendfile_header = 'X-Sendfile' # for Apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for NGINX

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :google_active_storage

  # Mount Action Cable outside main process or domain.
  # config.action_cable.mount_path = nil
  domain = ENV.fetch('KAMAL_DOMAIN', 'localhost')
  config.action_cable.url = "wss://#{domain}/cable"
  # Allow Action Cable requests from configured domain
  config.action_cable.allowed_request_origins = [%r{https?://#{Regexp.escape(domain)}}]

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # Disabled: SSL is handled by Cloudflare and kamal-proxy
  # config.force_ssl = true

  # Use the lowest log level to ensure availability of diagnostic information
  # when problems arise.
  config.log_level = :debug

  # Prepend all log lines with the following tags.
  config.log_tags = [:request_id]

  # Configure logger to show full error backtraces
  config.logger = ActiveSupport::Logger.new($stdout)
  config.logger.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity} -- #{progname}: #{msg}\n"
  end

  # Use a different cache store in production.
  # config.cache_store = :mem_cache_store

  # Use Solid Queue for Active Job
  config.active_job.queue_adapter = :solid_queue

  # Solid Queue logging configuration
  config.solid_queue.logger = ActiveSupport::Logger.new($stdout)
  config.solid_queue.logger.level = Logger::DEBUG
  config.solid_queue.logger.formatter = proc do |severity, datetime, progname, msg|
    "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] [SolidQueue] #{severity} -- #{progname}: #{msg}\n"
  end

  # Log all Active Job executions with full error details
  config.active_job.logger = ActiveSupport::Logger.new($stdout)
  config.active_job.logger.level = Logger::DEBUG

  config.action_mailer.perform_caching = false

  # Ignore bad email addresses and do not raise email delivery errors.
  # Set this to true and configure the email server for immediate delivery to raise delivery errors.
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: ENV.fetch('KAMAL_DOMAIN', 'localhost') }
  config.action_mailer.default charset: 'utf-8'
  config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method = :resend

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation cannot be found).
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners.
  config.active_support.deprecation = :notify

  # Use default logging formatter so that PID and timestamp are not suppressed.
  config.log_formatter = Logger::Formatter.new

  # Use a different logger for distributed setups.
  # require 'syslog/logger'
  # config.logger = ActiveSupport::TaggedLogging.new(Syslog::Logger.new 'app-name')

  if ENV['RAILS_LOG_TO_STDOUT'].present?
    logger           = ActiveSupport::Logger.new($stdout)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Inserts middleware to perform automatic connection switching.
  # The `database_selector` hash is used to pass options to the DatabaseSelector
  # middleware. The `delay` is used to determine how long to wait after a write
  # to send a subsequent read to the primary.
  #
  # The `database_resolver` class is used by the middleware to determine which
  # database is appropriate to use based on the time delay.
  #
  # The `database_resolver_context` class is used by the middleware to set
  # timestamps for the last write to the primary. The resolver uses the context
  # class timestamps to determine how long to wait before reading from the
  # replica.
  #
  # By default Rails will store a last write timestamp in the session. The
  # DatabaseSelector middleware is designed as such you can define your own
  # strategy for connection switching and pass that into the middleware through
  # these configuration options.
  # config.active_record.database_selector = { delay: 2.seconds }
  # config.active_record.database_resolver = ActiveRecord::Middleware::DatabaseSelector::Resolver
  # config.active_record.database_resolver_context = ActiveRecord::Middleware::DatabaseSelector::Resolver::Session

  # Configure Solid Cache database connection for production
  # Skip during asset precompilation when database may not be available
  if !ENV.fetch('SECRET_KEY_BASE_DUMMY', nil) && config.respond_to?(:solid_cache)
    config.solid_cache.connects_to = { database: { writing: :cache } }
  end

  # Configure Solid Cable database connection for production
  # Skip during asset precompilation when database may not be available
  if !ENV.fetch('SECRET_KEY_BASE_DUMMY', nil) && config.respond_to?(:solid_cable)
    config.solid_cable.connects_to = { database: { writing: :cable } }
  end

  # Configure Solid Queue database connection for production
  # Skip during asset precompilation when database may not be available
  if !ENV.fetch('SECRET_KEY_BASE_DUMMY', nil) && config.respond_to?(:solid_queue)
    config.solid_queue.connects_to = { database: { writing: :queue } }
  end
end
