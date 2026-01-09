# frozen_string_literal: true

require 'test_helper'

module Oroshi
  # NOTE: Invoice create/update/destroy actions use turbo_stream responses
  # and are tested at the system level. Request specs here verify GET endpoints
  # and model integration.
  class InvoicesTest < ActionDispatch::IntegrationTest
    setup do
      @user = create(:user, :admin)
      sign_in @user

      @supplier_org = create(:oroshi_supplier_organization)
      @supplier = create(:oroshi_supplier, supplier_organization: @supplier_org)
      @supply_date = create(:oroshi_supply_date, date: Time.zone.today)
      @supply_type_variation = @supplier.supply_type_variations.first
      @reception_time = @supplier_org.supply_reception_times.first
      @supply = create(:oroshi_supply,
                       supply_date: @supply_date,
                       supplier: @supplier,
                       supply_type_variation: @supply_type_variation,
                       supply_reception_time: @reception_time,
                       quantity: 10,
                       price: 100)
    end

    test 'GET /oroshi/invoices returns success' do
      get oroshi_invoices_path
      assert_response :success
    end

    test 'GET /oroshi/invoices with existing invoices lists invoices' do
      create(:oroshi_invoice, supply_dates: [@supply_date])

      get oroshi_invoices_path
      assert_response :success
    end

    test 'GET /oroshi/invoices/:id returns success' do
      invoice = create(:oroshi_invoice, supply_dates: [@supply_date])

      get oroshi_invoice_path(invoice)
      assert_response :success
    end

    test 'associates invoice with supply dates' do
      invoice = create(:oroshi_invoice, supply_dates: [@supply_date])

      assert_includes invoice.supply_dates, @supply_date
    end

    test 'can access supplies through supply dates' do
      invoice = create(:oroshi_invoice, supply_dates: [@supply_date])

      assert_includes invoice.supply_dates.flat_map(&:supplies), @supply
    end

    test 'can associate with supplier organizations' do
      invoice = create(:oroshi_invoice, supply_dates: [@supply_date])
      invoice.supplier_organizations << @supplier_org
      invoice.reload

      assert_includes invoice.supplier_organizations, @supplier_org
    end
  end
end
