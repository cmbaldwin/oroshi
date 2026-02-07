# frozen_string_literal: true

# Provides oroshi_* route helper aliases for backward compatibility
# Views were written when Oroshi was a standalone app with `namespace :oroshi` routes
# Now that it's an engine with `Oroshi::Engine.routes.draw`, helpers don't have the prefix
#
# This helper handles two patterns:
# 1. Methods starting with oroshi_: oroshi_root_path -> root_path
# 2. Methods containing _oroshi_: load_oroshi_products_path -> load_products_path
#
module Oroshi
  module UrlHelper
    # Dynamically define oroshi_* methods that delegate to the engine's route helpers
    def method_missing(method_name, *args, **kwargs, &block)
      engine_method = strip_oroshi_prefix(method_name)
      if engine_method && oroshi.respond_to?(engine_method)
        oroshi.public_send(engine_method, *args, **kwargs, &block)
      elsif method_name.to_s.include?("rails_") || method_name.to_s.include?("_blob_") || method_name.to_s.include?("_attachment_")
        # Delegate Active Storage and Rails service routes to main_app
        main_app.public_send(method_name, *args, **kwargs, &block) if respond_to?(:main_app) && main_app.respond_to?(method_name)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      engine_method = strip_oroshi_prefix(method_name)
      if engine_method && oroshi.respond_to?(engine_method)
        true
      elsif method_name.to_s.include?("rails_") || method_name.to_s.include?("_blob_") || method_name.to_s.include?("_attachment_")
        respond_to?(:main_app) && main_app.respond_to?(method_name)
      else
        super
      end
    end

    private

    # Returns the engine method name with oroshi_ removed, or nil if no match
    # Handles both:
    # - oroshi_root_path -> root_path
    # - load_oroshi_products_path -> load_products_path
    def strip_oroshi_prefix(method_name)
      name = method_name.to_s
      if name.start_with?("oroshi_")
        name.sub("oroshi_", "")
      elsif name.include?("_oroshi_")
        name.sub("_oroshi_", "_")
      else
        nil
      end
    end

    # Access to the engine's route helpers
    def oroshi
      Oroshi::Engine.routes.url_helpers
    end
  end
end
