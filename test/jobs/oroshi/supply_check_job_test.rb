# frozen_string_literal: true

require "test_helper"

class Oroshi::SupplyCheckJobTest < ActiveJob::TestCase
  setup do
    @message = create(:message, data: { filename: "supply_check.pdf" })
    @supply_date = Date.new(2025, 10, 8)
    @subregion_ids = [ 1, 2, 3 ]
    @supply_reception_time_ids = [ 1, 2 ]
    @supply_date_record = instance_double("Oroshi::SupplyDate", date: @supply_date)
    @supply_check = instance_double("SupplyCheck", render: "PDF content")

    # Stub Oroshi::SupplyDate
    supply_date_class = class_double("Oroshi::SupplyDate").as_stubbed_const
    allow(supply_date_class).to receive(:find_by).with(date: @supply_date).and_return(@supply_date_record)

    # Stub SupplyCheck PDF generation
    supply_check_class = class_double("SupplyCheck").as_stubbed_const
    allow(supply_check_class).to receive(:new).and_return(@supply_check)
  end

  test "finds the supply date record" do
    expect(Oroshi::SupplyDate).to receive(:find_by).with(date: @supply_date)
    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, @subregion_ids, @supply_reception_time_ids)
  end

  test "creates SupplyCheck with correct parameters" do
    expect(SupplyCheck).to receive(:new).with(@supply_date, @subregion_ids, @supply_reception_time_ids)
    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, @subregion_ids, @supply_reception_time_ids)
  end

  test "renders the PDF" do
    expect(@supply_check).to receive(:render)
    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, @subregion_ids, @supply_reception_time_ids)
  end

  test "attaches PDF to message" do
    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, @subregion_ids, @supply_reception_time_ids)
    @message.reload
    assert @message.stored_file.attached?
  end

  test "uses filename from message data" do
    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, @subregion_ids, @supply_reception_time_ids)
    @message.reload
    assert_equal "supply_check.pdf", @message.stored_file.filename.to_s
  end

  test "attaches with correct content type" do
    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, @subregion_ids, @supply_reception_time_ids)
    @message.reload
    assert_equal "application/pdf", @message.stored_file.content_type
  end

  test "updates message on completion" do
    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, @subregion_ids, @supply_reception_time_ids)
    @message.reload
    assert_equal true, @message.state
    assert_equal "\u7261\u8823\u539F\u6599\u53D7\u5165\u308C\u30C1\u30A7\u30C3\u30AF\u8868\u4F5C\u6210\u5B8C\u4E86\u3002", @message.message
  end

  # with different subregion and reception time combinations tests
  test "handles single subregion" do
    expect(SupplyCheck).to receive(:new).with(@supply_date, [ 1 ], @supply_reception_time_ids)
    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, [ 1 ], @supply_reception_time_ids)
  end

  test "handles empty arrays" do
    expect(SupplyCheck).to receive(:new).with(@supply_date, [], [])
    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, [], [])
  end

  test "handles multiple IDs" do
    large_subregion_ids = [ 1, 2, 3, 4, 5 ]
    large_reception_ids = [ 1, 2, 3 ]
    expect(SupplyCheck).to receive(:new).with(@supply_date, large_subregion_ids, large_reception_ids)
    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, large_subregion_ids, large_reception_ids)
  end
end
