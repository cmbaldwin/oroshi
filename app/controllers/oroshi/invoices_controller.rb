# frozen_string_literal: true

class Oroshi::InvoicesController < Oroshi::ApplicationController
  before_action :set_invoice, only: %i[show edit update destroy send_mail_now mail_notification_preview]
  before_action :set_invoice_with_params, only: %i[create]
  before_action :setup_show_invoice, only: %i[show edit create update]

  # GET /oroshi/invoice
  def index
    @invoices = Oroshi::Invoice.order(created_at: :desc).paginate(page: params[:page], per_page: 10)
  end

  # GET /oroshi/invoice/1
  def show; end

  # GET /oroshi/invoice/1/edit
  def edit
    render_modal
  end

  # POST /oroshi/invoice
  def create
    if @invoice.save
      process_invoice
      render_modal
    else
      render partial: "invoice", status: :unprocessable_entity
    end
  end

  # POST /oroshi/preview
  def preview
    process_preview
    head :ok
  end

  # PATCH/PUT /oroshi/invoice/1
  def update
    if @invoice.update(parsed_invoice_params)
      process_invoice
      render_modal
    else
      render partial: "invoice", status: :unprocessable_entity
    end
  end

  # DELETE /oroshi/invoice/1
  def destroy
    @invoice.destroy
  end

  # GET /oroshi/invoices/:id/send_mail_now
  def send_mail_now
    # create_message(model, state, message_text, data)
    message = create_message("send_oroshi_invoice_mail", false,
                             "\u4ECA\u3059\u3050\u4ED5\u5207\u308A\u66F8\u306E\u30E1\u30FC\u30EB\u3092\u9001\u4FE1\u4E2D\u2026", { oroshi_invoice_id: @invoice.id })
    Oroshi::MailerJob.perform_later(@invoice.id, message.id)
    head :ok
  end

  # GET /oroshi/invoices/:id/mail_notification_preview
  def mail_notification_preview
    @mails = {}
    @invoice.invoice_supplier_organizations.each do |join|
      mail = Oroshi::InvoiceMailer.invoice_notification(join.id)

      # Extract the HTML part from the multipart email
      if mail.multipart?
        html_part = mail.parts.find { |part| part.content_type.include?("text/html") }
        decoded_body = html_part.body.decoded.force_encoding("UTF-8") if html_part
      else
        decoded_body = mail.body.decoded.force_encoding("UTF-8")
      end

      # Extract the body style and the HTML
      doc = Nokogiri::HTML(decoded_body)
      body_style = doc.at_css("body")&.[]("style")
      html = decoded_body.html_safe

      # Extract attachments
      attachments = []
      if mail.multipart?
        mail.attachments.each do |attachment|
          attachments << attachment.filename
        end
      end

      @mails[join.supplier_organization.entity_name] = [ body_style, html, attachments ]
    end
    render partial: "oroshi/invoices/modal/mail_notification_preview"
  end

  private

  def render_modal
    respond_to do |format|
      format.turbo_stream do
        render "oroshi/supplies/modal/replace_supply_modal",
               locals: { path: "oroshi/supplies/modal/supply_invoice_actions" }
      end
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_invoice
    id = params[:id] || params[:invoice_id]
    @invoice = id ? Oroshi::Invoice.find(id) : Oroshi::Invoice.new
    @supplier_organizations = Oroshi::SupplierOrganization.active.by_supplier_count
  end

  def invoice_params
    params.require(:oroshi_invoice)
          .permit(:start_date, :end_date, :send_email, :send_at, :invoice_layout,
                  supplier_organization_ids: [], supply_date_ids: [])
  end

  def parsed_invoice_params
    parsed_params = invoice_params.dup
    invoice_params[:send_at].present? &&
      parsed_params[:send_at] = Time.zone.strptime(invoice_params[:send_at], "%Y\u5E74%m\u6708%d\u65E5 %H:%M")
    parsed_params
  end

  def set_invoice_with_params
    @invoice = Oroshi::Invoice.new(parsed_invoice_params)
  end

  def setup_show_invoice
    @supply_dates = Oroshi::SupplyDate.find(@invoice.supply_date_ids)
    @dates = [ *@invoice.start_date..@invoice.end_date ].map(&:to_s)
    @supplier_organizations = Oroshi::SupplierOrganization.active.by_supplier_count
  end

  def process_invoice
    message = invoice_message
    Oroshi::InvoiceJob
      .perform_later(@invoice.id, message.id)
  end

  def invoice_message
    data = {
      invoice_id: @invoice.id
    }
    create_message("oroshi_invoice", false, "\u4F9B\u7D66\u4ED5\u5207\u308A\u4F5C\u6210\u51E6\u7406\u4E2D\u2026", data)
  end

  def process_preview
    start_date, end_date, supplier_organization, invoice_format, layout =
      preview_params.values_at(:start_date, :end_date, :supplier_organization, :invoice_format, :layout)
    message = preview_message(start_date, end_date, supplier_organization, invoice_format, layout)
    Oroshi::InvoicePreviewJob
      .perform_later(start_date, end_date, supplier_organization, invoice_format, layout, message.id)
  end

  def preview_params
    params.permit(:start_date, :end_date, :supplier_organization, :invoice_format, :layout)
  end

  def preview_message(start_date, end_date, supplier_organization, invoice_format, layout)
    data = {
      invoice_id: 0,
      invoice_preview: {
        start_date: start_date,
        end_date: end_date,
        supplier_organization: supplier_organization,
        invoice_format: invoice_format,
        layout: layout
      }
    }
    create_message("oroshi_invoice", false, "\u4F9B\u7D66\u4ED5\u5207\u308A\u66F8\u30D7\u30EC\u30D3\u30E5\u30FC\u4F5C\u6210\u4E2D\u2026", data)
  end

  def create_message(model, state, message_text, data)
    message = Message.new(
      user: current_user.id,
      model: model,
      state: state,
      message: message_text,
      data: data.merge({ expiration: (DateTime.now + 1.day) })
    )
    message.save
    message
  end
end
