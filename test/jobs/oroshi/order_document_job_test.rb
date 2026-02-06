# frozen_string_literal: true

require "test_helper"

class Oroshi::OrderDocumentJobTest < ActiveJob::TestCase
  setup do
    @message = create(:message, data: {})
    @date = "2025-10-09"
    @document_type = "注文書"
    @shipping_organization_id = 123
    @print_empty_buyers = true
    @options = { key: "value" }
  end

  test "creates OroshiOrderDocument with correct parameters" do
    pdf_double = stub(render: "PDF content")

    OroshiOrderDocument.expects(:new).with(
      @date,
      @document_type,
      @shipping_organization_id,
      @print_empty_buyers,
      @options
    ).returns(pdf_double)

    Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id, @print_empty_buyers, @options)
  end

  test "attaches PDF to message" do
    pdf_double = stub(render: "PDF content")
    OroshiOrderDocument.stubs(:new).returns(pdf_double)

    Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id, @print_empty_buyers, @options)
    @message.reload
    assert @message.stored_file.attached?
  end

  test "sets filename in message data" do
    pdf_double = stub(render: "PDF content")
    OroshiOrderDocument.stubs(:new).returns(pdf_double)

    Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id, @print_empty_buyers, @options)
    @message.reload
    assert_match(/\(#{@date}\) - #{@document_type}/, @message.data[:filename])
    assert_match(/\[\d{14}\]\.pdf/, @message.data[:filename])
  end

  test "updates message with success status" do
    pdf_double = stub(render: "PDF content")
    OroshiOrderDocument.stubs(:new).returns(pdf_double)

    Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id, @print_empty_buyers, @options)
    @message.reload
    assert_equal true, @message.state
    assert_equal "注文書類作成完了", @message.message
  end

  test "triggers garbage collection" do
    pdf_double = stub(render: "PDF content")
    OroshiOrderDocument.stubs(:new).returns(pdf_double)
    GC.expects(:start)

    Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id, @print_empty_buyers, @options)
  end

  test "filename includes date, document type, and timestamp" do
    job = Oroshi::OrderDocumentJob.new
    filename = job.send(:filename, @document_type, @date)

    assert_includes filename, @date
    assert_includes filename, @document_type
    assert_match(/\[\d{14}\]\.pdf/, filename)
  end

  test "filename formats correctly" do
    job = Oroshi::OrderDocumentJob.new
    filename = job.send(:filename, "注文書", "2025-10-09")

    assert_match(/\(2025-10-09\) - 注文書 \[\d{14}\]\.pdf/, filename)
  end

  test "filename removes extra whitespace" do
    job = Oroshi::OrderDocumentJob.new
    filename = job.send(:filename, "Document  Type", @date)

    refute_includes filename, "  "
  end

  test "handles empty options hash" do
    pdf_double = stub(render: "PDF content")
    OroshiOrderDocument.stubs(:new).returns(pdf_double)

    assert_nothing_raised do
      Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id, @print_empty_buyers, {})
    end
  end

  test "handles print_empty_buyers as false" do
    pdf_double = stub(render: "PDF content")
    OroshiOrderDocument.stubs(:new).returns(pdf_double)

    assert_nothing_raised do
      Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id, false, @options)
    end
  end

  test "passes options through to OroshiOrderDocument" do
    custom_options = { custom_key: "custom_value" }
    pdf_double = stub(render: "PDF content")

    OroshiOrderDocument.expects(:new).with(
      @date,
      @document_type,
      @shipping_organization_id,
      @print_empty_buyers,
      custom_options
    ).returns(pdf_double)

    Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id, @print_empty_buyers, custom_options)
  end
end
