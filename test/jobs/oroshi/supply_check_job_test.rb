# frozen_string_literal: true

require "test_helper"

class Oroshi::SupplyCheckJobTest < ActiveJob::TestCase
  setup do
    @message = create(:message, data: { filename: "supply_check.pdf" })
    @supply_date = Date.new(2025, 10, 8)
    @subregion_ids = [ 1, 2, 3 ]
    @supply_reception_time_ids = [ 1, 2 ]
  end

  test "attaches PDF to message" do
    supply_date_record = stub(date: @supply_date)
    supply_check = stub(render: "PDF content")

    Oroshi::SupplyDate.stubs(:find_by).with(date: @supply_date).returns(supply_date_record)
    SupplyCheck.stubs(:new).returns(supply_check)

    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, @subregion_ids, @supply_reception_time_ids)
    @message.reload
    assert @message.stored_file.attached?
  end

  test "uses filename from message data" do
    supply_date_record = stub(date: @supply_date)
    supply_check = stub(render: "PDF content")

    Oroshi::SupplyDate.stubs(:find_by).with(date: @supply_date).returns(supply_date_record)
    SupplyCheck.stubs(:new).returns(supply_check)

    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, @subregion_ids, @supply_reception_time_ids)
    @message.reload
    assert_equal "supply_check.pdf", @message.stored_file.filename.to_s
  end

  test "attaches with correct content type" do
    supply_date_record = stub(date: @supply_date)
    supply_check = stub(render: "PDF content")

    Oroshi::SupplyDate.stubs(:find_by).with(date: @supply_date).returns(supply_date_record)
    SupplyCheck.stubs(:new).returns(supply_check)

    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, @subregion_ids, @supply_reception_time_ids)
    @message.reload
    assert_equal "application/pdf", @message.stored_file.content_type
  end

  test "updates message on completion" do
    supply_date_record = stub(date: @supply_date)
    supply_check = stub(render: "PDF content")

    Oroshi::SupplyDate.stubs(:find_by).with(date: @supply_date).returns(supply_date_record)
    SupplyCheck.stubs(:new).returns(supply_check)

    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, @subregion_ids, @supply_reception_time_ids)
    @message.reload
    assert_equal true, @message.state
    assert_equal "牡蠣原料受入れチェック表作成完了。", @message.message
  end

  test "finds supply date and creates SupplyCheck with correct parameters" do
    supply_date_record = stub(date: @supply_date)
    supply_check = stub(render: "PDF content")

    Oroshi::SupplyDate.expects(:find_by).with(date: @supply_date).returns(supply_date_record)
    SupplyCheck.expects(:new).with(@supply_date, @subregion_ids, @supply_reception_time_ids).returns(supply_check)

    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, @subregion_ids, @supply_reception_time_ids)
  end

  test "handles single subregion" do
    supply_date_record = stub(date: @supply_date)
    supply_check = stub(render: "PDF content")

    Oroshi::SupplyDate.stubs(:find_by).returns(supply_date_record)
    SupplyCheck.expects(:new).with(@supply_date, [ 1 ], @supply_reception_time_ids).returns(supply_check)

    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, [ 1 ], @supply_reception_time_ids)
  end

  test "handles empty arrays" do
    supply_date_record = stub(date: @supply_date)
    supply_check = stub(render: "PDF content")

    Oroshi::SupplyDate.stubs(:find_by).returns(supply_date_record)
    SupplyCheck.expects(:new).with(@supply_date, [], []).returns(supply_check)

    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, [], [])
  end

  test "handles multiple IDs" do
    large_subregion_ids = [ 1, 2, 3, 4, 5 ]
    large_reception_ids = [ 1, 2, 3 ]
    supply_date_record = stub(date: @supply_date)
    supply_check = stub(render: "PDF content")

    Oroshi::SupplyDate.stubs(:find_by).returns(supply_date_record)
    SupplyCheck.expects(:new).with(@supply_date, large_subregion_ids, large_reception_ids).returns(supply_check)

    Oroshi::SupplyCheckJob.perform_now(@supply_date, @message.id, large_subregion_ids, large_reception_ids)
  end
end
