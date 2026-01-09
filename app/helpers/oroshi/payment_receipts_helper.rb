# frozen_string_literal: true

module Oroshi::PaymentReceiptsHelper
  # Payment Receipt Dashboard Nav
  def payment_receipt_nav_item(path_string, active = false, **)
    content_tag(:li, class: "nav-item", **) do
      link_to t(".#{path_string}"), string_to_path(path_string),
              class: "nav-link #{'active' if active}",
              data: { turbo_frame: "payment_receipts_dashboard",
                      action: "oroshi--payment-receipts--dashboard#toggleActiveLink:passive" }
    end
  end

  def string_to_path(string)
    send("oroshi_payment_receipts_#{string}_path")
  end

  # Payment Receipt Dashboard Search Results Header
  def display_search_date(params)
    convert_date = ->(date_str) { Date.parse(date_str).strftime("%Y\u5E74%m\u6708%d\u65E5") }
    start_date = convert_date.call(params[:q][:deposit_date_gteq])
    end_date = convert_date.call(params[:q][:deposit_date_lteq])
    "#{start_date} ~ #{end_date} "
  end

  # Payment Receipts Form (modal)
  def link_to_add_fields(name, form, association)
    new_object = form.object.send(association).klass.new
    id = new_object.object_id
    fields = form.fields_for(association, new_object, child_index: id) do |builder|
      render("#{association.to_s.singularize}_fields", form: builder)
    end
    link_to(name, "#", class: "add_fields btn btn-sm btn-success",
                       data: { id: id, fields: fields.gsub("\n", ""),
                               action: "oroshi--payment-receipts--dashboard#addAdjustment:prevent" })
  end

  def buyer_select_options
    options = Oroshi::Buyer.active.order_by_associated_system_id.map do |buyer|
      [ "#{buyer.name} (#{buyer.handle})", buyer.id, { data: { color: buyer.color } } ]
    end
    options_for_select options
  end
end
