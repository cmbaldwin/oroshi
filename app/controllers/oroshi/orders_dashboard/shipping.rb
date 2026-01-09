# frozen_string_literal: true

module Oroshi
  module OrdersDashboard
    module Shipping
      extend ActiveSupport::Concern

      included do
        # Callbacks
        before_action :set_shipping_orders, only: %i[shipping]
        before_action :filter_order_document_params, only: %i[shipping_chart shipping_list shipping_slips]
      end

      # GET /oroshi/orders/:date/shipping
      def shipping
        handle_dashboard_response('shipping')
      end

      # GET /oroshi/orders/:date/shipping_chart(.:format)
      def shipping_chart
        @shipping_organization = shipping_document_params[:shipping_organization_id]
        @print_empty_buyers = shipping_document_params[:print_empty_buyers]
        generate_shipping_document('shipping_chart')
      end

      # GET /oroshi/orders/:date/shipping_list(.:format)
      def shipping_list
        head :ok
      end

      # GET /oroshi/orders/:date/shipping_slips(.:format)
      def shipping_slips
        head :ok
      end

      private

      def set_shipping_orders
        @orders = Oroshi::Order.non_template.where(shipping_date: @date)
                               .includes(:order_categories, :buyer, :product, :shipping_organization,
                                         shipping_method: %i[buyers],
                                         product_variation: %i[supply_type_variations product])
        set_filters
        @grouped_orders = @grouped_orders.group_by(&:shipping_organization)
        @products = Oroshi::Product.all.includes(%i[product_variations supply_type])
      end

      def filter_order_document_params
        @order_document_options = {
          order_category_ids: shipping_document_params[:order_category_ids]&.reject(&:blank?),
          buyer_category_ids: shipping_document_params[:buyer_category_ids]&.reject(&:blank?),
          buyer_ids: shipping_document_params[:buyer_ids]&.reject(&:blank?),
          shipping_method_ids: shipping_document_params[:shipping_method_ids]&.reject(&:blank?)
        }.compact
      end

      def shipping_document_params
        params.permit(:print_empty_buyers, :shipping_organization_id, :button, :action, :date, :format,
                      order_category_ids: [], buyer_category_ids: [], buyer_ids: [], shipping_method_ids: [])
      end

      def generate_shipping_document(document_type)
        message = shipping_document_messsage(document_type)
        Oroshi::OrderDocumentJob.perform_later(@date, document_type, message.id, @shipping_organization,
                                               @print_empty_buyers, @order_document_options)
      end

      def shipping_document_messsage(document_type)
        data = {
          date: @date,
          document_type:
        }
        create_message('oroshi_order_document', false,
                       "\u51FA\u8377\u66F8\u985E\u3092\u4F5C\u6210\u51E6\u7406\u4E2D\u2026", data)
      end

      def create_message(model, state, message_text, data)
        message = Message.new(
          user: current_user.id,
          model: model,
          state: state,
          message: message_text,
          data: data.merge({ expiration: (DateTime.now + 1.day) })
        )
        message.save
        message
      end
    end
  end
end
