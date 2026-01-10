# frozen_string_literal: true

module Oroshi
  module OrdersDashboard
    module TemplateView
  extend ActiveSupport::Concern

  included do
    # Callbacks
    before_action :set_templates, only: %i[templates]
  end

  # POST /oroshi/orders/:date/form
  def templates
    handle_dashboard_response("templates") do
      # @grouped_templates is set by set_filters, but may be nil if no templates exist
      # Group by product for the view, defaulting to empty hash if nil
      @grouped_templates = (@grouped_templates || []).group_by { |template| template.order.product }
    end
  end

  private

  def set_templates
    @order_templates = Oroshi::OrderTemplate
                       .all.includes(:order_categories,
                                     order: %i[buyer product_variation
                                               shipping_receptacle])

    set_filters
  end
    end
  end
end
