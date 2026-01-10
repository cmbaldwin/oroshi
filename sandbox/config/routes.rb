Rails.application.routes.draw do
  # Mount the Oroshi engine
  mount Oroshi::Engine, at: "/"

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check
end
