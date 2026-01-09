# frozen_string_literal: true

module Oroshi
  class SupplyCheckJob < ApplicationJob
    queue_as :default

    def perform(supply_date, message_id, subregion_ids, supply_reception_time_ids)
      message = Message.find(message_id)
      # Find supply_date record (may be used by SupplyCheck internally)
      Oroshi::SupplyDate.find_by(date: supply_date)

      pdf_data = SupplyCheck.new(supply_date, subregion_ids, supply_reception_time_ids)
      io = StringIO.new pdf_data.render

      message.stored_file.attach(io: io, content_type: 'application/pdf', filename: message.data[:filename])
      message.update(state: true,
                     message: "\u7261\u8823\u539F\u6599\u53D7\u5165\u308C\u30C1\u30A7\u30C3\u30AF\u8868\u4F5C\u6210\u5B8C\u4E86\u3002")
    end
  end
end
