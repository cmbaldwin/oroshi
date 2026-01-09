# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class ProductionZoneTest < ActiveSupport::TestCase
    def setup
      @production_zone = build(:oroshi_production_zone)
    end

    test 'is valid with valid attributes' do
      assert @production_zone.valid?
    end

    # Validations
    test 'is not valid without a name' do
      @production_zone.name = nil
      assert_not @production_zone.valid?
    end

    test 'is not valid without active' do
      @production_zone.active = nil
      assert_not @production_zone.valid?
    end
  end
end
