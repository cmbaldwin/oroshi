# frozen_string_literal: true

class ServiceConfiguration < ApplicationRecord
  # Available services
  SERVICES = {
    google_cloud_storage: {
      name: "Google Cloud Storage",
      description: "Store files on Google Cloud Platform",
      required_credentials: [ "project", "bucket", "credentials_path" ]
    },
    hetzner_object_storage: {
      name: "Hetzner Object Storage",
      description: "Store files on Hetzner S3-compatible storage",
      required_credentials: [ "access_key", "secret_key", "endpoint", "bucket" ]
    },
    aws_s3: {
      name: "AWS S3",
      description: "Store files on Amazon S3",
      required_credentials: [ "access_key_id", "secret_access_key", "region", "bucket" ]
    },
    sendgrid: {
      name: "SendGrid",
      description: "Send emails via SendGrid",
      required_credentials: [ "api_username", "api_password", "mail_sender" ]
    },
    resend: {
      name: "Resend",
      description: "Send emails via Resend",
      required_credentials: [ "api_key" ]
    },
    smtp: {
      name: "SMTP",
      description: "Send emails via SMTP",
      required_credentials: [ "host", "port", "username", "password" ]
    },
    rakuten: {
      name: "Rakuten Ichiba",
      description: "Rakuten marketplace integration",
      required_credentials: [ "api_key", "service_secret", "license_key" ]
    },
    yahoo_v2: {
      name: "Yahoo Shopping (V2)",
      description: "Yahoo Shopping API V2 integration",
      required_credentials: [ "client_id", "client_secret", "seller_id" ]
    },
    yahoo_v1: {
      name: "Yahoo Shopping (V1 - Legacy)",
      description: "Yahoo Shopping API V1 (legacy support)",
      required_credentials: [ "secret", "client_id" ]
    },
    infomart: {
      name: "Infomart",
      description: "Infomart B2B platform integration",
      required_credentials: [ "login", "password" ]
    }
  }.freeze

  # Validations
  validates :service, presence: true, uniqueness: true
  validates :service, inclusion: { in: SERVICES.keys.map(&:to_s) }

  # Scopes
  scope :enabled, -> { where(enabled: true) }

  # Class methods
  def self.enabled?(service_name)
    find_by(service: service_name.to_s)&.enabled? || false
  end

  def self.setup_defaults
    SERVICES.each_key do |service|
      find_or_create_by!(service: service.to_s) do |config|
        config.enabled = false
        config.description = SERVICES[service][:description]
      end
    end
  end

  # Instance methods
  def service_info
    SERVICES[service.to_sym] || {}
  end

  def service_name
    service_info[:name] || service.titleize
  end

  def required_credentials
    service_info[:required_credentials] || []
  end

  def fully_configured?
    return false unless enabled?

    required_credentials.all? do |key_name|
      Credential.active.where(service: service, key_name: key_name).exists?
    end
  end
end
