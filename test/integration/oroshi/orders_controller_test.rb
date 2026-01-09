# frozen_string_literal: true

require "test_helper"

class Oroshi::OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    sign_in @admin
    @oroshi_order = create(:oroshi_order)
    @oroshi_order_template = create(:oroshi_order_template)
    @today = Time.zone.today
    @oroshi_order_attributes = build_order_attributes
  end

  # GET #index
  test "GET index redirects to index with date without order" do
    get oroshi_orders_path
    # should redirect to the same index but with todays date
    assert_redirected_to oroshi_orders_path(@today)
  end

  test "GET index shows index with date and no order" do
    get oroshi_orders_path, params: { date: @today }
    assert_response :success
  end

  test "GET index returns http success with order" do
    get oroshi_orders_path, params: { date: @today }
    assert_response :success
  end

  # GET #edit
  test "GET edit returns http success" do
    get edit_oroshi_order_path(@oroshi_order)
    assert_response :success
  end

  # POST #create
  test "POST create creates a new Oroshi::Order with valid parameters" do
    assert_difference("Oroshi::Order.count", 1) do
      post oroshi_orders_path, params: { oroshi_order: @oroshi_order_attributes }
    end
  end

  test "POST create does not create a new Oroshi::Order with invalid parameters" do
    @oroshi_order_attributes[:shipping_date] = nil
    assert_no_difference("Oroshi::Order.count") do
      post oroshi_orders_path, params: { oroshi_order: @oroshi_order_attributes }
    end
  end

  test "POST create returns unprocessable_entity status with invalid parameters" do
    @oroshi_order_attributes[:shipping_date] = nil
    post oroshi_orders_path, params: { oroshi_order: @oroshi_order_attributes }
    assert_response :unprocessable_entity
  end

  # PATCH #update
  test "PATCH update updates the requested oroshi_order with valid parameters" do
    new_date = Time.zone.tomorrow
    new_shipping_date = new_date.strftime("%Y\u5E74%m\u6708%d\u65E5")
    patch oroshi_order_path(@oroshi_order), params: {
      oroshi_order: {
        shipping_date: new_shipping_date,
        # simulate the flatpickr date format for both dates
        arrival_date: @oroshi_order.arrival_date.strftime("%Y\u5E74%m\u6708%d\u65E5")
      }
    }
    @oroshi_order.reload
    assert_equal new_date, @oroshi_order.shipping_date
  end

  # DELETE #destroy
  test "DELETE destroy destroys the requested oroshi_order" do
    assert_difference("Oroshi::Order.count", -1) do
      delete oroshi_order_path(@oroshi_order)
    end
  end

  private

  def build_order_attributes
    attributes = attributes_for(:oroshi_order).dup
    # Convert date objects to Japanese format strings for form submission
    %i[shipping_date arrival_date manufacture_date expiration_date].each do |date_attr|
      attributes[date_attr] = attributes[date_attr]&.strftime("%Y\u5E74%m\u6708%d\u65E5")
    end
    # Fix association IDs
    attributes[:buyer_id] = create(:oroshi_buyer).id
    product_variation = create(:oroshi_product_variation)
    attributes[:product_variation_id] = product_variation.id
    attributes[:shipping_receptacle_id] = product_variation.default_shipping_receptacle.id
    attributes[:shipping_method_id] = create(:oroshi_shipping_method).id
    attributes
  end
end
