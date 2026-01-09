# frozen_string_literal: true

# Below uses recommendations from https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server

# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
threads_count = Integer(ENV["RAILS_MAX_THREADS"] || 5)
threads threads_count, threads_count

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port ENV.fetch("PORT", 3000)

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RACK_ENV", "development")

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE", "tmp/pids/server.pid")

# Specifies the number of `workers` to boot in clustered mode.
# macOS + forked workers can crash when hitting native frameworks (seen in pg).
if ENV.fetch("RACK_ENV", "development") == "development"
  workers 0
else
  workers Integer(ENV["WEB_CONCURRENCY"] || 1)
  on_worker_boot do
    # See: https://devcenter.heroku.com/articles/deploying-rails-applications-with-the-puma-web-server#on-worker-boot
    ActiveRecord::Base.establish_connection
  end
  preload_app!
end

# Allow puma to be restarted by `rails restart` command.
plugin :tmp_restart
