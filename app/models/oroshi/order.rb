# frozen_string_literal: true

module Oroshi
  class Order < ApplicationRecord
    include ActionView::RecordIdentifier # for broadcasts
    include Oroshi::Ransackable

    # Associations
    belongs_to :buyer, class_name: 'Oroshi::Buyer'
    belongs_to :product_variation, class_name: 'Oroshi::ProductVariation'
    has_one :product, through: :product_variation
    belongs_to :product_inventory, class_name: 'Oroshi::ProductInventory'
    belongs_to :shipping_receptacle, class_name: 'Oroshi::ShippingReceptacle'
    belongs_to :shipping_method, class_name: 'Oroshi::ShippingMethod'
    has_one :shipping_organization, through: :shipping_method
    has_many :order_order_categories, class_name: 'Oroshi::Order::OrderCategory', dependent: :destroy
    has_many :order_categories, through: :order_order_categories
    has_one :order_template, class_name: 'Oroshi::OrderTemplate', inverse_of: :order, dependent: :destroy
    belongs_to :payment_receipt, class_name: 'Oroshi::PaymentReceipt', optional: true

    # Enumerables
    enum :status, { estimate: 0, confirmed: 1, shipped: 2 }

    # Validations
    validates :arrival_date, :shipping_date, :manufacture_date, :expiration_date, presence: true
    validates :item_quantity, :receptacle_quantity, :freight_quantity,
              presence: true, numericality: { greater_than: 0 }
    validates :shipping_cost, :materials_cost, :sale_price_per_item, :adjustment,
              presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :note, length: { maximum: 255 }

    # Attributes
    attr_accessor :previous_item_quantity, :data, :is_order_template, :copy_template, :stored_associable_template
    attr_writer :manufacture_date, :expiration_date

    def manufacture_date
      product_inventory&.manufacture_date || @manufacture_date
    end

    def expiration_date
      product_inventory&.expiration_date || @expiration_date
    end

    def counts
      [item_quantity, receptacle_quantity, freight_quantity]
    end

    # Callbacks
    before_validation :set_or_create_product_inventory, on: %i[create update]
    after_validation :calculate_costs
    before_update :store_previous_product_inventory
    before_update :store_previous_item_quantity
    after_update :update_product_inventory
    after_update :check_and_destroy_previous_product_inventory
    before_destroy :restore_product_inventory
    after_destroy :check_and_destroy_product_inventory
    before_save :handle_order_template
    after_save :touch_order_template

    # Scopes
    # Orders associated as templates do not count as actual orders
    scope :non_template, -> { where.not(id: Oroshi::OrderTemplate.select(:order_id).distinct) }
    scope :by_order_category, lambda { |order_category_id|
      joins(:order_order_categories)
        .where(order_order_categories: { order_category_id: order_category_id })
    }
    scope :payment_orphans, -> { where(payment_receipt_id: nil) }
    # To be used in the future
    # scope :estimate, -> { where(status: statuses[:estimate]) }
    # scope :confirmed, -> { where(status: statuses[:confirmed]) }
    # scope :unshipped, -> { where.not(status: statuses[:shipped]) }
    # scope :shipped, -> { where(status: statuses[:shipped]) }
    # scope :sold, -> { where.not(sale_price_per_item: 0) }

    # Broadcasts (Best guide on them: https://blog.corsego.com/turbo-hotwire-broadcasts)
    after_create_commit -> { broadcast_replace_to [shipping_date, :oroshi_orders_list] }
    after_update_commit lambda {
      # When an order is created it gets updated again because of the order_category association
      # Use this to broadcast replacement of the template across user view streams
      template = associable_template
      broadcast_replace_to [shipping_date, :oroshi_orders_list], target: dom_id(template) if template.present?
    }
    after_update_commit lambda {
      broadcast_replace_to [shipping_date, :oroshi_orders_list], target: dom_id(self)
    }
    after_destroy_commit :broadcast_destroy

    # Methods
    # Used primarily for selection of bundable orders
    def to_s
      "#{buyer.handle} #{shipping_date} #{model_name.human}#{id} - #{product_variation} * #{item_quantity} [#{shipping_receptacle.handle}*#{receptacle_quantity}]"
    end

    # Revenue and expenses calculations
    def revenue
      sale_price_per_item * item_quantity
    end

    def revenue_minus_handling
      revenue * buyer.commission_percentage
    end

    def expenses
      materials_cost + shipping_cost - adjustment
    end

    def total
      revenue - expenses
    end

    # Filtering, sorting, and broadcasting deletion
    def associable_template
      return order_template if order_template.present?

      # find the order template with an order that has the same buyer, product variation, shipping receptacle, and order_categories
      Oroshi::OrderTemplate.joins(order: %i[buyer product_variation shipping_receptacle order_categories])
                           .where(
                             oroshi_orders: { buyer_id: buyer.id, product_variation_id: product_variation.id,
                                              shipping_receptacle_id: shipping_receptacle.id },
                             oroshi_order_categories: { id: order_categories.pluck(:id) }
                           )
                           .first
    end

    private

    # Inventory management setup
    def set_or_create_product_inventory
      self.product_inventory = Oroshi::ProductInventory.find_or_create_by(
        product_variation:,
        manufacture_date:,
        expiration_date:
      )
    end

    def store_previous_product_inventory
      @previous_product_inventory = product_inventory
    end

    def check_and_destroy_previous_product_inventory
      return unless @previous_product_inventory.orders.unscoped.empty?

      @previous_product_inventory.destroy
    end

    def check_and_destroy_product_inventory
      return unless product_inventory.orders.unscoped.empty?

      product_inventory.destroy
    end

    # Cost calculation
    def calculate_costs
      self.shipping_cost = calculate_shipping_cost
      self.materials_cost = calculate_materials_cost
    end

    def calculate_shipping_cost
      # If the order is bundled with another order, the shipping costs are 0 for this one
      return 0 if bundled_with_order_id.present?

      # Shipping method costs
      per_receptacle_shipping_method_cost = shipping_method&.per_shipping_receptacle_cost || 0
      per_freight_shipping_method_cost = shipping_method&.per_freight_unit_cost || 0
      # Buyer costs
      buyer_handling_cost = buyer&.handling_cost || 0
      buyer_optional_cost = add_buyer_optional_cost ? buyer.optional_cost : 0
      # Shipping subtotals
      receptacle_shipping_cost = receptacle_quantity * (buyer_handling_cost + buyer_optional_cost + per_receptacle_shipping_method_cost)
      freight_cost = freight_quantity * per_freight_shipping_method_cost
      # Total shipping cost
      receptacle_shipping_cost + freight_cost
    end

    def calculate_materials_cost
      receptacle_cost = bundled_shipping_receptacle ? 0 : (shipping_receptacle&.cost || 0) * receptacle_quantity
      product_cost = product&.material_cost(shipping_receptacle,
                                            item_quantity:,
                                            receptacle_quantity:,
                                            freight_quantity:) || 0
      packaging_cost = (product_variation&.packaging_cost || 0) * item_quantity
      receptacle_cost + product_cost + packaging_cost
    end

    # Inventory management
    def store_previous_item_quantity
      self.previous_item_quantity = item_quantity_was if shipped? || status_was == 'shipped'
    end

    def update_product_inventory
      return unless shipped?

      difference = previous_item_quantity - item_quantity
      # Use the order's product_inventory association, not product_variation's
      inventory = product_inventory

      if status_before_last_save == 'shipped' # Was already shipped, record difference
        inventory.quantity += difference
      else # Was moved to shipped, subtract quantity
        inventory.quantity -= item_quantity
      end
      self.data = attributes
      inventory.save!
    end

    def restore_product_inventory
      return unless shipped?

      # Use the order's product_inventory association
      inventory = product_inventory
      inventory.quantity += item_quantity
      inventory.save!
    end

    def handle_order_template
      if is_order_template && !order_template.present?
        Oroshi::OrderTemplate.create(order: self)
      elsif !is_order_template && order_template.present?
        order_template.destroy
      end
    end

    def touch_order_template
      order_template&.touch if order_template&.persisted?
    end

    # Broadcasts
    def broadcast_destroy
      if @stored_associable_template
        broadcast_replace_to(
          [shipping_date, :oroshi_orders_list],
          target: dom_id(self),
          partial: 'oroshi/orders/dashboard/orders/template',
          locals: { order_template: @stored_associable_template }
        )
      else
        broadcast_remove_to [shipping_date, :oroshi_orders_list]
      end
    end
  end
end
