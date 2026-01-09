# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class OrderDocumentJobTest < ActiveJob::TestCase
    setup do
      @message = create(:message)
      @date = '2025-10-09'
      @document_type = "\u6CE8\u6587\u66F8"
      @shipping_organization_id = 123
      @print_empty_buyers = true
      @options = { key: 'value' }
      @pdf_double = instance_double('OroshiOrderDocument', render: 'PDF content')
      @stored_file_double = instance_double('ActiveStorage::Attached::One')

      allow(Message).to receive(:find).with(@message.id).and_return(@message)
      allow(OroshiOrderDocument).to receive(:new).and_return(@pdf_double)
      allow(@message).to receive(:stored_file).and_return(@stored_file_double)
      allow(@stored_file_double).to receive(:attach)
      allow(@message).to receive(:update)
      allow(@message).to receive(:data).and_return({})
      allow(GC).to receive(:start)
    end

    test 'finds the message' do
      Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id,
                                           @print_empty_buyers, @options)

      assert_received(Message, :find).with(@message.id)
    end

    test 'creates OroshiOrderDocument with correct parameters' do
      Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id,
                                           @print_empty_buyers, @options)

      assert_received(OroshiOrderDocument, :new).with(
        @date,
        @document_type,
        @shipping_organization_id,
        @print_empty_buyers,
        @options
      )
    end

    test 'renders the PDF' do
      Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id,
                                           @print_empty_buyers, @options)

      assert_received(@pdf_double, :render)
    end

    test 'sets filename in message data' do
      Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id,
                                           @print_empty_buyers, @options)

      assert_match(/\(#{@date}\) - #{@document_type}/, @message.data[:filename])
      assert_match(/\[\d{14}\]\.pdf/, @message.data[:filename])
    end

    test 'attaches PDF to message with correct parameters' do
      Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id,
                                           @print_empty_buyers, @options)

      assert_received(@stored_file_double, :attach) do |args|
        assert_kind_of StringIO, args[:io]
        assert_equal 'application/pdf', args[:content_type]
        assert_match(/\.pdf$/, args[:filename])
      end
    end

    test 'updates message with success status' do
      Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id,
                                           @print_empty_buyers, @options)

      assert_received(@message, :update).with(state: true, message: "\u6CE8\u6587\u66F8\u985E\u4F5C\u6210\u5B8C\u4E86")
    end

    test 'triggers garbage collection' do
      Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id,
                                           @print_empty_buyers, @options)

      assert_received(GC, :start)
    end

    test 'filename includes date, document type, and timestamp' do
      job = Oroshi::OrderDocumentJob.new

      filename = job.send(:filename, @document_type, @date)

      assert_includes filename, @date
      assert_includes filename, @document_type
      assert_match(/\[\d{14}\]\.pdf/, filename)
    end

    test 'filename formats correctly' do
      job = Oroshi::OrderDocumentJob.new

      filename = job.send(:filename, "\u6CE8\u6587\u66F8", '2025-10-09')

      assert_match(/\(2025-10-09\) - 注文書 \[\d{14}\]\.pdf/, filename)
    end

    test 'filename removes extra whitespace' do
      job = Oroshi::OrderDocumentJob.new

      filename = job.send(:filename, 'Document  Type', @date)

      refute_includes filename, '  '
    end

    # with different options tests
    test 'handles empty options hash' do
      assert_nothing_raised do
        Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id,
                                             @print_empty_buyers, {})
      end
    end

    test 'handles print_empty_buyers as false' do
      assert_nothing_raised do
        Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id, false,
                                             @options)
      end
    end

    test 'passes options through to OroshiOrderDocument' do
      custom_options = { custom_key: 'custom_value' }

      Oroshi::OrderDocumentJob.perform_now(@date, @document_type, @message.id, @shipping_organization_id,
                                           @print_empty_buyers, custom_options)

      assert_received(OroshiOrderDocument, :new).with(
        @date,
        @document_type,
        @shipping_organization_id,
        @print_empty_buyers,
        custom_options
      )
    end
  end
end
