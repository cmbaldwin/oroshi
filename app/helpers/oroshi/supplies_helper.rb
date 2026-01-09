# frozen_string_literal: true

module Oroshi::SuppliesHelper
  def supply_link(supplier_organization, supply_reception_time)
    button_to entry_oroshi_supply_date_path(@supply_date.date,
                                            supplier_organization_id: supplier_organization.id,
                                            supply_reception_time_id: supply_reception_time.id),
              supply_link_params(supply_reception_time) do
      supply_link_text(supplier_organization, supply_reception_time)
    end
  end

  def supply_link_params(supply_reception_time)
    color_class = supply_reception_time.hour < 12 ? "list-group-item-light" : "list-group-item-dark"
    { id: "list-entry-tab-list",
      form_class: "entry-link-form list-group-item list-group-item-action #{color_class} text-center small p-0",
      class: "btn btn-link text-decoration-none text-dark text-truncate w-100 h-100",
      role: "tab",
      aria_controls: "list-entry-tab",
      data: {
        action: "oroshi--supplies--supply-date#selectEntry",
        oroshi__supplies__supply_date_target: "entryLink"
      } }
  end

  def supply_link_text(supplier_organization, supply_reception_time)
    [
      supplier_organization.micro_region,
      supply_reception_time.time_qualifier,
      "(#{supplier_organization.subregion})"
    ].join(" ")
  end

  def supply_tab_panel(&block)
    content_tag :div,
                id: "list-entry-tab",
                class: "tab-pane text-center p-2 fade show active",
                role: "tabpanel",
                aria: {
                  labelledby: "list-entry-tab-list"
                } do
      content_tag(:div, class: "container-xl") do
        content_tag(:div, class: "card mw-lg overflow-auto") do
          content_tag(:div, class: "card-body overflow-auto") { block.call }
        end
      end
    end
  end

  def supply_quantity_field(form, supply)
    disable = !supply.supplier.supply_type_variations.include?(supply.supply_type_variation) || supply.locked
    disabled = disable ? { disabled: true } : {}
    input_class = "quantity form-control small text-center focus-ring focus-ring-light #{'disabled' if disable}"

    form.number_field :quantity,
                      id: "supply_quantity_#{supply.id || unique_input_id(supply)}",
                      class: input_class,
                      style: "width: 3rem;",
                      value: format_number(supply.quantity),
                      placeholder: "\u6570\u91CF",
                      data: {
                        controller: "oroshi--supplies--supply-date-input",
                        action: "focus->oroshi--supplies--supply-date#selectText",
                        oroshi__supplies__supply_date_target: "input",
                        oroshi__supplies__supply_date_input_target: "input"
                      },
                      **disabled
  end

  def supply_price_field(form, supply)
    disable = !supply.supplier.supply_type_variations.include?(supply.supply_type_variation) || supply.locked
    disabled = disable ? { disabled: true } : {}
    input_class = "price d-none form-control small text-center focus-ring focus-ring-light #{'disabled' if disable}"

    form.number_field :price,
                      id: "supply_price_#{supply.id || unique_input_id(supply)}",
                      class: input_class,
                      style: "width: 3.4rem;",
                      value: format_number(supply.price),
                      placeholder: "\u5024\u6BB5",
                      data: {
                        action: "focus->oroshi--supplies--supply-date#selectText",
                        oroshi__supplies__supply_date_target: "price",
                        controller: "oroshi--supplies--supply-date-price"
                      },
                      **disabled
  end

  def unique_input_id(supply)
    "#{supply.supplier_id}_#{supply.supply_type_variation_id}_#{supply.entry_index}"
  end

  def format_number(number)
    number.to_i == number ? number.to_i : number
  end

  def find_variants(supply_dates, suppliers)
    get_variants = ->(models) { models.map(&:supply_type_variations).flatten.uniq }
    supply_date_variants = get_variants.call(supply_dates)
    supplier_variants = get_variants.call(suppliers)
    variants = supply_date_variants & supplier_variants
    variants.sort!
  end

  def oroshi_price_fields(basket_prices_form, index, variants, supplier_organization_id)
    content_tag :div do
      variants.map do |variant|
        concat(oroshi_price_field(index, basket_prices_form, variant, supplier_organization_id))
      end
    end
  end

  def oroshi_price_field(index, basket_prices_form, variant, supplier_organization_id)
    content_tag(:div, class: "input-group input-group-sm mb-1") do
      concat oroshi_price_field_label(index, variant, supplier_organization_id)
      concat basket_prices_form.text_field(variant.id, class: "form-control", type: "number")
    end
  end

  def oroshi_price_field_label(index, variant, supplier_organization_id)
    data_action = if index.positive?
                    { action: "click->oroshi--supplies--supply-price-actions#copyPrice",
                      controller: "tippy",
                      tippy_content: "<center>\u30AF\u30EA\u30C3\u30AF\u3057\u305F\u3089\u4E00\u756A\u524D\u306E\u540C\u3058\u7A2E\u985E\u306E\u5358\u4FA1\u3092\u3053\u3053\u306B\u30B3\u30D4\u30FC\u3057\u307E\u3059</center>" }
    else
                    {}
    end
    content_tag(:span,
                type_to_japanese(variant),
                class: "input-group-text p-1 no-select #{'cursor-pointer' if index.positive?}",
                style: "font-size: 0.75rem;",
                data: {
                  **data_action,
                  price_type: variant.id,
                  supplier_organization_id: supplier_organization_id
                })
  end

  def oroshi_invoice_preview_link(icon, supplier_organization, invoice_format, layout)
    link_to icon(icon),
            oroshi_invoice_preview_path(
              start_date: @dates.first,
              end_date: @dates.last,
              supplier_organization:,
              invoice_format:,
              layout:
            ),
            class: "btn ms-2 tippy #{layout == 'standard' ? 'btn-light' : 'btn-secondary'}",
            data: {
              controller: "tippy",
              tippy_content: oroshi_invoice_preview_tippy_content(invoice_format, layout, supplier_organization),
              turbo_prefetch: false
            }
  end

  def oroshi_invoice_preview_tippy_content(invoice_format, layout, supplier_organization)
    [ "<center>",
     supplier_organization.entity_name,
     "の#{invoice_format == 'organization' ? '組織版' : '生産者版'}",
     "\u306E<br>\u4ED5\u5207\u308A\u30D7\u30EC\u30D3\u30E5\u30FC\u3092\u4F5C\u6210<br>(",
     layout == "simple" ? "\u7C21\u6613\u7248)" : "\u6A19\u6E96\u7248)",
     "</center>" ].join
  end

  def oroshi_supply_completion_span(supply)
    bg_color_class = oroshi_supply_bg_color(supply)
    content_tag(:span, "", class: "completion input-group-text p-1#{bg_color_class}")
  end

  def oroshi_supply_bg_color(supply)
    incomplete = (supply.quantity.to_f.positive? && supply.price.to_f.zero?) ||
                 (supply.quantity.to_f.zero? && supply.price.to_f.nonzero?)
    incomplete ? " bg-yellow" : ""
  end

  def pdf_password_cell(join, invoice)
    content_tag :td,
                class: "cursor-pointer tippy",
                data: {
                  controller: "tippy",
                  tippy_content: "\u30AF\u30EA\u30C3\u30AF\u3057\u3066\u30B3\u30D4\u30FC"
                } do
      content_tag :samp,
                  join.passwords[invoice.id.to_s],
                  data: {
                    action: "click->oroshi--supplies--invoice#copy"
                  }
    end
  end
end
