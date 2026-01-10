# frozen_string_literal: true

# FrozenStringLiteral: true

require "prawn"
require "prawn/table"
require "open-uri"

# Printable - PrawnPDF Initializer
class Printable < Prawn::Document
  # Usage: class MyDocument < Printable
  #          def initialize
  #            super
  #            # ... do stuff
  #          end
  #        end
  #        MyDocument.new.render_file('my_document.pdf')
  # Or, render to io and attach to model with ActiveStorage:
  #        io = StringIO.new MyDocument.new.render
  #        model.file.attach(io: io, content_type: 'application/pdf', filename: 'my_document.pdf')

  def initialize(page_size: "A4", page_layout: :portrait, margin: [ 15 ])
    super
    font_families.update(fonts)
    font "MPLUS1p" # default font
    Carmen.i18n_backend.locale = :ja # set locale to Japanese
  end

  def company_info
    settings = Setting.find_by(name: "oroshi_company_settings")&.settings
    return company_info_text_backup unless settings

    <<~INFO
      <b>〒#{settings['postal_code']} </b>
      #{settings['address']}
      #{settings['name']}
      #{phone_and_fax(settings['phone'], settings['fax'])}
      メール: #{settings['mail']}
    INFO
  end

  def company_info_text_backup
    "<b>〒678-0215</b>
      兵庫県赤穂市御崎151-2
      株式会社MOAB
      TEL +81-791-25-4986
      メール [email protected]"
  end

  def phone_and_fax(phone, fax)
    print_non_nil = ->(prefix, text) { "#{prefix} #{text}" if text }
    "#{print_non_nil.call('TEL', phone)} #{print_non_nil.call('FAX', fax)}"
  end

  def rakuten_info
    <<~RAKUTEN_INFO
      株式会社船曳商店#{' 　'}
      OYSTER SISTERS
      〒678-0232
      兵庫県赤穂市中広1576－11
      TEL: 0791-42-3645
      FAX: 0791-43-8151
      店舗運営責任者: 船曳　晶子
    RAKUTEN_INFO
  end

  def funabiki_info
    <<~FUNABIKI_INFO
      株式会社船曳商店#{' 　'}
      〒678-0232
      兵庫県赤穂市中広1576－11
      TEL: 0791-42-3645
      FAX: 0791-43-8151
      メール: info@funabiki.info
      ウエブ: www.funabiki.info
    FUNABIKI_INFO
  end

  def invoice_number
    "\u767B\u9332\u756A\u53F7 T3140002034095"
  end

  private

  def fonts
    {
      "MPLUS1p" => mplus_font_paths,
      "Sawarabi" => sawarabi_font_paths,
      "TakaoPMincho" => takao_font_path
    }
  end

  def mplus_font_paths
    {
      normal: font_path("MPLUS1p-Regular.ttf"),
      bold: font_path("MPLUS1p-Bold.ttf"),
      light: font_path("MPLUS1p-Light.ttf")
    }
  end

  def sawarabi_font_paths
    # Must be used for names, this font includes almost all Japanese characters
    { normal: font_path("SawarabiMincho-Regular.ttf") }
  end

  def takao_font_path
    { normal: font_path("TakaoPMincho.ttf") }
  end

  def font_path(font_name)
    # Use engine font path if available, otherwise fall back to Rails.root
    if defined?(Oroshi::Fonts)
      Oroshi::Fonts.font_path(font_name)
    else
      Rails.root.join("app/assets/fonts/#{font_name}").to_s
    end
  end

  def root(file)
    Rails.root.join(file)
  end

  def oysis_logo
    root("app/assets/images/oysis.jpg")
  end

  def funabiki_logo
    root("app/assets/images/logo_ns.png")
  end

  def jp_format(date)
    date.strftime("%Y\u5E74%m\u6708%d\u65E5")
  end

  def funabiki_header(alt_address)
    funa_cell = { content: funabiki_info, size: 8 }
    alt_cell = { content: alt_address, size: 8 }
    [ alt_cell, { image: funabiki_logo, scale: 0.065, position: :center }, funa_cell ]
  end

  def funabiki_footer(format_created_date, _format_updated_date)
    funa_cell = { content: funabiki_info, size: 10, padding: 3, colspan: 3 }
    logo_cell = { image: @funabiki_logo, scale: 0.065, colspan: 4, position: :center }
    created_cell = { content: %(
      <b><font size="12">作成日・更新日</font></b>
      #{jp_format(format_created_date)}
      #{jp_format(format_updates_date)}
      ), size: 10, padding: 3, colspan: 3, align: :right }
    [ funa_cell, logo_cell, created_cell ]
  end

  def fetch_cached_suppliers
    @sakoshi_suppliers = Rails.cache.fetch "sakoshi_suppliers" do
      Supplier.where(location: "\u5742\u8D8A").order(:supplier_number)
    end
    @aioi_suppliers = Rails.cache.fetch "aioi_suppliers" do
      Supplier.where(location: "\u76F8\u751F").order(:supplier_number)
    end
  end

  def set_supply_variables
    fetch_cached_suppliers
    @supplier_numbers = @sakoshi_suppliers.pluck(:id).map(&:to_s)
    @supplier_numbers += @aioi_suppliers.pluck(:id).map(&:to_s)
    @types = %w[large small eggy damaged large_shells small_shells thin_shells
                small_triploid_shells triploid_shells large_triploid_shells xl_triploid_shells]
  end

  def type_to_japanese(type)
    { "large" => "\u3080\u304D\u8EAB\uFF08\u5927\uFF09", "small" => "\u3080\u304D\u8EAB\uFF08\u5C0F\uFF09", "eggy" => "\u3080\u304D\u8EAB\uFF08\u5375\uFF09", "damaged" => "\u3080\u304D\u8EAB\uFF08\u30AD\u30BA\uFF09",
      "large_shells" => "\u6BBB\u4ED8\u304D\uFF08\u5927\uFF09", "small_shells" => "\u6BBB\u4ED8\u304D\uFF08\u5C0F\uFF09", "thin_shells" => "\u30D0\u30E9\u6BBB\u4ED8\u304D\uFF08kg\uFF09",
      "small_triploid_shells" => "\u6BBB\u4ED8\u304D\u7261\u8823\uFF08\u4E09\u500D\u4F53\u3000M\uFF09", "triploid_shells" => "\u6BBB\u4ED8\u304D\u7261\u8823\uFF08\u4E09\u500D\u4F53\u3000L\uFF09",
      "large_triploid_shells" => "\u6BBB\u4ED8\u304D\u7261\u8823\uFF08\u4E09\u500D\u4F53\u3000LL\uFF09", "xl_triploid_shells" => "\u6BBB\u4ED8\u304D\u7261\u8823\uFF08\u4E09\u500D\u4F53\u3000LLL\uFF09" }[type]
  end

  def type_to_unit(type)
    { "large" => "kg", "small" => "kg", "eggy" => "kg", "damaged" => "kg", "large_shells" => "\u500B",
      "small_shells" => "\u500B", "thin_shells" => "kg", "small_triploid_shells" => "\u500B",
      "triploid_shells" => "\u500B", "large_triploid_shells" => "\u500B", "xl_triploid_shells" => "\u500B" }[type]
  end

  def yenify(number, unit: "", delimiter: ",")
    ActionController::Base.helpers.number_to_currency(number, locale: :ja, unit: unit, delimiter: delimiter)
  end
end
