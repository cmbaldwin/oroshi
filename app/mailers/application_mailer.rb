# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  require 'resend'

  default from: ENV.fetch('MAIL_SENDER', nil)
  layout 'mailer'

  def to_nengapi(date)
    date&.strftime("%Y\u5E74%m\u6708%d\u65E5")
  end
end
