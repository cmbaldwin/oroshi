# frozen_string_literal: true

# Union Invoicetable crafting module - Mixin for Supplier Invoice PDF generator
# 簡易版 or Simple style layout, created 2023
module OroshiInvoice
  module InvoiceLayoutTwo
    private

    # Header
    def layout_two_header
      table([
              header_row,
              supply_dates_row,
              invoice_date_row,
              receiver_and_invoice_number_row,
              total_payment_row
            ], width: bounds.width * 0.75, position: :center) do
        self.cell_style = { borders: [] }
      end
    end

    def header_row
      [{ content: "\u652F\u6255\u660E\u7D30\u66F8", colspan: 2, font_style: :bold, size: 18, align: :center,
         padding_bottom: 10 }]
    end

    def supply_dates_row
      [{ content: print_supply_dates, colspan: 2, size: 12, align: :center, padding_bottom: 20 }]
    end

    def invoice_date_row
      date = l(@invoice_date || supply_dates.last.date, format: :long)
      [{ content: date, size: 10, colspan: 2, font: 'TakaoPMincho', align: :right }]
    end

    def receiver_and_invoice_number_row
      [{ content: receiver_info_text,
         size: 10, font: 'TakaoPMincho', align: :center, padding_top: 20,
         inline_format: true, leading: 5, width: 200 },
       { content: company_info_text,
         size: 10, font: 'TakaoPMincho', align: :center, valign: :bottom, padding_top: 60,
         padding_bottom: 50, leading: 5, inline_format: true }]
    end

    def receiver_info_text
      "#{formatted_name}\n登録番号：#{current_receiver.invoice_number}"
    end

    def formatted_name
      "<u>#{circled_number}#{current_receiver.invoice_name}　#{current_receiver.honorific_title}</u>"
    end

    def circled_number
      return '' unless current_receiver.is_a?(Oroshi::Supplier)

      "#{current_receiver.circled_number} "
    end

    def current_receiver
      @current_supplier || @supplier_organization
    end

    def total_payment_row
      [{ content: "<u>支払金額合計： #{en_it(@invoice_subtotal + @tax_subtotal)}</u>",
         font_style: :bold, size: 12, inline_format: true, colspan: 2 }]
    end

    # Body
    def invoice_table_two
      table([
              ["\u6708\u65E5", { content: "\u5546\u54C1\u540D", colspan: 2 }, "\u6570\u91CF", "\u5358\u4FA1",
               "\u91D1\u984D"],
              *@invoice_rows,
              *tax_rows
            ], width: bounds.width) do # * 0.75, position: :center
        self.cell_style = { border_width: 0.25, size: 9 }
        self.header = true
        row(0).style align: :center
      end
    end

    def tax_rows
      [[{ content: "\u5408\u8A08", colspan: 2, align: :center },
        { content: "\u4ED5\u5165\u984D", colspan: 2, align: :center },
        { content: "\u6D88\u8CBB\u7A0E\u984D\u7B49", colspan: 2, align: :center }],
       [{ content: "8%\u5BFE\u8C61", colspan: 2, align: :center },
        { content: en_it(@invoice_subtotal), colspan: 2, align: :center },
        { content: en_it(@tax_subtotal), colspan: 2, align: :center }],
       [{ content: "10%\u5BFE\u8C61", colspan: 2, align: :center },
        { content: "0\u5186", colspan: 2, align: :center },
        { content: "0\u5186", colspan: 2, align: :center }]]
    end
  end
end
