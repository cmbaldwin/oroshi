# frozen_string_literal: true

# Provides oroshi_* route helper aliases for backward compatibility
# Views were written when Oroshi was a standalone app with `namespace :oroshi` routes
# Now that it's an engine with `Oroshi::Engine.routes.draw`, helpers don't have the prefix
module Oroshi
  module UrlHelper
    # Dynamically define oroshi_* methods that delegate to the engine's route helpers
    def method_missing(method_name, *args, **kwargs, &block)
      if method_name.to_s.start_with?("oroshi_") && respond_to_engine_route?(method_name)
        engine_method = method_name.to_s.sub("oroshi_", "")
        oroshi.public_send(engine_method, *args, **kwargs, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      (method_name.to_s.start_with?("oroshi_") && respond_to_engine_route?(method_name)) || super
    end

    private

    def respond_to_engine_route?(method_name)
      engine_method = method_name.to_s.sub("oroshi_", "")
      oroshi.respond_to?(engine_method)
    end

    # Access to the engine's route helpers
    def oroshi
      Oroshi::Engine.routes.url_helpers
    end
  end
end
