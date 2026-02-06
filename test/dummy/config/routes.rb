# Dummy Application Routes for Testing
# =====================================
#
# This mimics how a real parent application would configure Oroshi.
# The User model and Devise routes live at the application level,
# while Oroshi provides all the wholesale order management features.

Rails.application.routes.draw do
  # Devise routes for User authentication
  # The User model is at the application level (not inside the engine)
  devise_for :users

  # Health check route (standard in Rails 8+)
  get "up", to: proc { [200, {}, ["OK"]] }

  # Mount Oroshi engine at /oroshi
  mount Oroshi::Engine => "/oroshi"

  # Root redirects to Oroshi dashboard
  root to: redirect("/oroshi")
end
