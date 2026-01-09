# frozen_string_literal: true

desc "Check for mail that needs to be sent and send it"
task mail_check_and_send: :environment do
  Oroshi::MailerJob.perform_later
end
