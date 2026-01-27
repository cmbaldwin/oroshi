# frozen_string_literal: true

require "application_system_test_case"

class OroshiOrdersDashboardTest < ApplicationSystemTestCase
  include JavaScriptTest

  setup do
    @admin = create(:user, :admin)
    # Skip onboarding for admin user
    create(:onboarding_progress, :completed, user: @admin)
    login_as(@admin, scope: :user)
    @date = Time.zone.today
  end

  test "loads orders view without errors" do
    create_dashboard_data

    # First visit the main orders index page which sets up the turbo frame
    visit oroshi_orders_path(date: @date)

    # Debug where we ended up
    puts "\n" + "=" * 80
    puts "Current URL after visit: #{page.current_url}"
    puts "Page title: #{page.title}"

    if page.title.include?("Exception")
      File.write("tmp/test_error_index.html", page.html)
      puts "Error page saved to tmp/test_error_index.html"
      # Try to find the error
      if page.has_selector?("h2")
        puts "Error: #{page.all("h2").first.text}"
      end
    end
    puts "=" * 80 + "\n"

    # Wait for page to load
    assert_selector "body", wait: 5

    # Now the turbo frame should lazy-load from oroshi_orders_orders_path
    # Wait for the lazy frame to load its content
    assert_selector "turbo-frame#orders_dashboard", wait: 15
    assert_no_text "Content missing"
  end

  test "loads templates view without errors" do
    create_dashboard_data
    visit oroshi_orders_templates_path(date: @date)
    assert_selector "turbo-frame#orders_dashboard", wait: 10
    assert_no_text "Content missing"
  end

  test "loads supply usage view without errors" do
    create_dashboard_data
    visit oroshi_orders_supply_usage_path(date: @date)
    assert_selector "turbo-frame#orders_dashboard", wait: 10
    assert_no_text "Content missing"
  end

  test "loads production view without errors" do
    create_dashboard_data
    visit oroshi_orders_production_path(date: @date)
    assert_selector "turbo-frame#orders_dashboard", wait: 10
    assert_no_text "Content missing"
  end

  test "loads shipping view without errors" do
    create_dashboard_data
    visit oroshi_orders_shipping_path(date: @date)
    assert_selector "turbo-frame#orders_dashboard", wait: 10
    assert_no_text "Content missing"
  end

  test "loads sales view without errors" do
    create_dashboard_data
    visit oroshi_orders_sales_path(date: @date)
    assert_selector "turbo-frame#orders_dashboard", wait: 10
    assert_no_text "Content missing"
  end

  test "loads revenue view without errors" do
    create_dashboard_data
    visit oroshi_orders_revenue_path(date: @date)
    assert_selector "turbo-frame#orders_dashboard", wait: 10
    assert_no_text "Content missing"
  end

  private

  def create_dashboard_data
    # Create supply type and variation
    @supply_type = create(:oroshi_supply_type)
    @supply_type_variation = create(:oroshi_supply_type_variation, supply_type: @supply_type)

    # Create product and variation
    @product = create(:oroshi_product, supply_type: @supply_type)
    @product_variation = create(:oroshi_product_variation, product: @product)

    # Create production zone and link to product variation
    @production_zone = create(:oroshi_production_zone)
    @product_variation.production_zones << @production_zone

    # Create product inventory with manufacture_date matching @date
    @product_inventory = create(:oroshi_product_inventory,
                                 product_variation: @product_variation,
                                 manufacture_date: @date)

    # Create buyer
    @buyer = create(:oroshi_buyer)

    # Create shipping organization
    @shipping_organization = create(:oroshi_shipping_organization)

    # Create shipping method
    @shipping_method = create(:oroshi_shipping_method)

    # Create shipping receptacle
    @shipping_receptacle = create(:oroshi_shipping_receptacle)

    # Create order with shipping_date matching @date
    @order = create(:oroshi_order,
                    buyer: @buyer,
                    product_variation: @product_variation,
                    shipping_receptacle: @shipping_receptacle,
                    shipping_method: @shipping_method,
                    shipping_date: @date,
                    manufacture_date: @date)

    # Create order template with same associations
    @order_template = create(:oroshi_order_template,
                             order: create(:oroshi_order,
                                           buyer: @buyer,
                                           product_variation: @product_variation,
                                           shipping_receptacle: @shipping_receptacle,
                                           shipping_method: @shipping_method))

    # Create supplier organization
    @supplier_organization = create(:oroshi_supplier_organization)

    # Create supplier
    @supplier = create(:oroshi_supplier, supplier_organization: @supplier_organization)

    # Link supplier to supply type variation
    @supplier.supply_type_variations << @supply_type_variation

    # Create supply date
    @supply_date = create(:oroshi_supply_date, date: @date)

    # Create supply
    @supply = create(:oroshi_supply,
                     supplier: @supplier,
                     supply_date: @supply_date,
                     supply_type_variation: @supply_type_variation,
                     supply_reception_time: @supplier_organization.supply_reception_times.first)
  end
end
