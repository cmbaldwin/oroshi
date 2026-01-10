Rails.application.routes.draw do
  mount Oroshi::Engine => "/oroshi"
  root to: redirect("/oroshi")
end
