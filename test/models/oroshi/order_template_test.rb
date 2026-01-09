# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class OrderTemplateTest < ActiveSupport::TestCase
    def setup
      @order_template = build(:oroshi_order_template)
    end

    test 'is valid with valid attributes' do
      assert @order_template.valid?
    end

    # Validations
    test 'is not valid without an order' do
      @order_template.order = nil
      assert_not @order_template.valid?
    end

    # Associations
    test 'belongs to an order' do
      order_template = create(:oroshi_order_template)
      assert_instance_of Oroshi::Order, order_template.order
    end
  end
end
