# frozen_string_literal: true

module Oroshi
  class InvoiceMailer < ApplicationMailer
    require 'open-uri'

    def invoice_notification(invoice_supplier_organization_id)
      @invoice_supplier_organization = Oroshi::Invoice::SupplierOrganization.find(invoice_supplier_organization_id)
      @header = header.gsub("\n", '<br>').strip
      @company_info = company_info
      process_attachments

      supplier_email = @invoice_supplier_organization.supplier_organization.email
      company_email = Setting.find_by(name: 'oroshi_company_settings')&.settings&.dig('mail')

      # If supplier has no email, send to company as primary recipient
      # Otherwise, send to supplier with company as CC
      if supplier_email.blank?
        mail(to: company_email,
             from: default_from,
             subject: subject.gsub("\n", ' ').strip,
             template_path: 'oroshi/invoices/mailer')
      else
        mail(to: supplier_email,
             from: default_from,
             cc: company_email,
             subject: subject.gsub("\n", ' ').strip,
             template_path: 'oroshi/invoices/mailer')
      end
    end

    def process_attachments
      @invoice_supplier_organization.invoices.each do |invoice|
        invoice.blob.open do |file|
          attachments[invoice.blob.filename.to_s] = file.read
        end
      end
    end

    def company_info
      settings = Setting.find_by(name: 'oroshi_company_settings')&.settings
      return company_info_text_backup unless settings

      <<~INFO
        <b>#{settings['name']}</b><br>
        〒#{settings['postal_code']}<br>
        #{settings['address']}<br>
        #{phone_and_fax(settings['phone'], settings['fax'])}<br>
        メール: #{settings['mail']}<br>
      INFO
    end

    def company_info_text_backup
      "<b>株式会社MOAB</b><br>
        〒678-0215<br>
        兵庫県赤穂市御崎151-2<br>
        TEL +81-791-25-4986<br>
        メール [email protected]<br>"
    end

    def phone_and_fax(phone, fax)
      print_non_nil = ->(prefix, text) { "#{prefix} #{text}" if text }
      "#{print_non_nil['TEL', phone]}<br>
      #{print_non_nil['FAX', fax]}"
    end

    private

    def default_from
      ENV.fetch('MAIL_SENDER', nil) || Setting.find_by(name: 'oroshi_company_settings')&.settings&.dig('mail')
    end

    def subject
      company_name = Setting.find_by(name: 'oroshi_company_settings')&.settings&.dig('name')
      invoice = @invoice_supplier_organization.invoice
      supplier_organization = @invoice_supplier_organization.supplier_organization
      date_range_string = [invoice.start_date, invoice.end_date]
                          .map { |date| l(date, format: :long) }
                          .join(" \u301C ")
      <<~HEREDOC
        #{company_name} ー #{supplier_organization.micro_region} 支払い明細書（#{date_range_string}）
      HEREDOC
    end

    def header
      invoice = @invoice_supplier_organization.invoice
      supplier_organization = @invoice_supplier_organization.supplier_organization
      date_range_string = [invoice.start_date, invoice.end_date]
                          .map { |date| l(date, format: :long) }
                          .join(" \u301C ")
      <<~HEREDOC
        #{supplier_organization.entity_name}
        (#{supplier_organization.subregion} - #{supplier_organization.micro_region} )
        【 #{date_range_string} 】の 支払い明細書
      HEREDOC
    end
  end
end
