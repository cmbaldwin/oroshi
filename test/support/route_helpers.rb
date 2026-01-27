module OroshiRouteHelpers
  # Access engine routes via Oroshi::Engine.routes.url_helpers
  def oroshi
    Oroshi::Engine.routes.url_helpers
  end

  def method_missing(method, *args, **kwargs, &block)
    if method.to_s.start_with?("oroshi_") || method.to_s.include?("_oroshi_")
      target_method = method.to_s.sub(/^oroshi_/, "").gsub("_oroshi_", "_")
      if oroshi.respond_to?(target_method)
        oroshi.public_send(target_method, *args, **kwargs, &block)
      else
        super
      end
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    if method.to_s.start_with?("oroshi_") || method.to_s.include?("_oroshi_")
      target_method = method.to_s.sub(/^oroshi_/, "").gsub("_oroshi_", "_")
      oroshi.respond_to?(target_method) || super
    else
      super
    end
  end
end
