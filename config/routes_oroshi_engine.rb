# frozen_string_literal: true

# Oroshi Engine Routes
# This file will eventually replace the namespace block in config/routes.rb
Oroshi::Engine.routes.draw do
  root to: "dashboard#index"

  # Onboarding wizard
  resources :onboarding, only: [ :index, :show, :update ] do
    member do
      post :skip
      post :resume
    end
    collection do
      post :dismiss_checklist
    end
  end

  namespace :dashboard do
    %w[home suppliers_organizations supply_types
       shipping buyers materials products stats company].each do |tab|
      get tab
    end
    get "subregions"
    post "company_settings"
  end

  resources :supply_reception_times, except: %i[destroy show]

  resources :order_categories, except: %i[show]

  resources :supplier_organizations, except: %i[show destroy] do
    get "load", on: :collection
    get "load", on: :member
    resources :suppliers, only: %i[new index]
  end

  resources :suppliers, except: %i[destroy show]

  resources :supply_types, except: %i[destroy show] do
    get "load", on: :collection
    get "load", on: :member
    resources :supply_type_variations, only: %i[new index]
  end

  resources :supply_type_variations, except: %i[destroy show] do
    patch "update_positions", on: :collection
  end

  resources :supply_dates, param: :date, except: :destroy do
    post "entry/:supplier_organization_id/:supply_reception_time_id",
         on: :member, to: "supply_dates#entry", as: :entry
    get "checklist/:subregion_ids/:supply_reception_time_ids",
        on: :member, to: "supply_dates#checklist", as: :checklist
    get "supply_invoice_actions", on: :collection
    get "supply_price_actions", on: :collection
    post "set_supply_prices", on: :collection
  end

  resources :supplies, except: %i[new destroy]
  get "supplies/entry", to: "supplies#new", as: :supply_entry

  get "invoices/preview", as: :invoice_preview, to: "invoices#preview"
  resources :invoices do
    get :send_mail_now, on: :member
    get :mail_notification_preview, on: :member
  end

  resources :shipping_organizations, except: :destroy do
    get "load", on: :collection
    get "load", on: :member
    resources :shipping_methods, only: %i[new index]
  end

  resources :shipping_methods, except: %i[destroy show]

  resources :buyer_categories, except: %i[show]

  resources :buyers, except: %i[destroy show] do
    get "orders/:date", on: :member, to: "buyers#bundlable_orders", as: :bundlable_orders
    get "outstanding_payment_orders", on: :member, to: "buyers#outstanding_payment_orders",
                                      as: :outstanding_payment_orders
  end

  resources :shipping_receptacles, except: %i[destroy show] do
    get "image", on: :member
    get "estimate_per_box_quantity/:product_variation_id",
        to: "shipping_receptacles#estimate_per_box_quantity",
        on: :member
  end

  resources :packagings, except: %i[destroy show] do
    get "image", on: :member
    get "images", on: :collection
  end

  resources :material_categories, except: %i[destroy show] do
    resources :materials, only: %i[index]
  end

  resources :materials, except: %i[destroy show] do
    get "image", on: :member
    get "images", on: :collection
  end

  resources :products, except: %i[destroy] do
    get "load", on: :collection
    get "load", on: :member
    resources :product_variations, only: %i[new index]
    get "material_cost/:shipping_receptacle_id/:item_quantity/:receptacle_quantity/:freight_quantity",
        on: :member,
        to: "products#material_cost"
    patch "update_positions", on: :collection
  end

  resources :product_variations, except: %i[destroy] do
    get "load", on: :collection
    get "load", on: :member
    get "image", on: :member
    get "cost", on: :member
  end

  resources :production_zones, except: %i[destroy show]

  get "orders/calendar", to: "orders#calendar", as: :orders_calendar
  get "orders/calendar/orders", to: "orders#calendar_orders", as: :calendar_orders
  get "orders/search", to: "orders#search", as: :search_orders
  get "orders(/:date)", to: "orders#index", as: :orders
  get "orders(/:date)/new", to: "orders#new", as: :new_order
  post "orders/from_template/:template_id", to: "orders#new_order_from_template", as: :new_order_from_template
  delete "orders/templates/:template_id", to: "orders#destroy_template", as: :delete_template
  patch "orders/:id/quantity_update", to: "orders#quantity_update", as: :quantity_update_order
  patch "orders/:id/price_update", to: "orders#price_update", as: :price_update_order

  scope "orders/:date", as: :orders do
    %w[orders templates supply_usage production shipping sales revenue].each do |route|
      get "/#{route}", to: "orders##{route}", as: route.to_sym
    end

    # Shipping view document generators
    get "/shipping_chart", to: "orders#shipping_chart", as: :order_shipping_chart
    get "/shipping_list", to: "orders#shipping_list", as: :order_shipping_list
    get "/shipping_slips", to: "orders#shipping_slips", as: :order_shipping_slips

    # Supply Usage view sub-frames
    get "/supply_volumes", to: "orders#supply_volumes", as: :order_supply_volumes
    get "/product_inventories", to: "orders#product_inventories", as: :order_product_inventories
    get "/production_view/:production_view", to: "orders#production_view", as: :order_production_view

    # Sales view sub-frame
    get "/buyer_sales/:buyer_id", to: "orders#buyer_sales", as: :buyer_sales
  end

  resources :orders, except: %i[index new show] do
    get "show", to: "orders#show", as: :show
  end

  resources :product_inventories, except: %i[destroy] do
    resources :production_requests, only: %i[index]
  end

  resources :production_requests, except: %i[index] do
    get "convert/:date(/:product_id)", on: :collection, to: "production_requests#convert", as: :convert
  end

  resources :payment_receipt_adjustment_types, except: %i[destroy show]
  resources :payment_receipt_adjustments, except: %i[index]
  %w[quick_entry single_entry search buyer_outstanding_list].each do |action|
    get "payment_receipts/#{action}", to: "payment_receipts##{action}", as: "payment_receipts_#{action}"
  end
  get "payment_receipts/buyer/:buyer_id", to: "payment_receipts#buyer_outstanding",
                                          as: "payment_receipts_buyer_outstanding"
  resources :payment_receipts
end
