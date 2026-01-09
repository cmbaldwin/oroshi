# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class PackagingTest < ActiveSupport::TestCase
    def setup
      @packaging = build(:oroshi_packaging)
    end

    test 'is valid with valid attributes' do
      assert @packaging.valid?
    end

    # Validations
    test 'is not valid without a name' do
      @packaging.name = nil
      assert_not @packaging.valid?
    end

    test 'is not valid without a cost' do
      @packaging.cost = nil
      assert_not @packaging.valid?
    end

    test 'is not valid without active' do
      @packaging.active = nil
      assert_not @packaging.valid?
    end
  end
end
