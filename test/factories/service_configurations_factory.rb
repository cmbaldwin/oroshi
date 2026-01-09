# frozen_string_literal: true

FactoryBot.define do
  factory :service_configuration do
    service { 'google_cloud_storage' }
    enabled { false }
    description { 'Google Cloud Storage configuration' }

    trait :enabled do
      enabled { true }
    end

    trait :disabled do
      enabled { false }
    end

    trait :sendgrid do
      service { 'sendgrid' }
      description { 'SendGrid email service' }
    end

    trait :rakuten do
      service { 'rakuten' }
      description { 'Rakuten e-commerce API' }
    end

    trait :hetzner_storage do
      service { 'hetzner_object_storage' }
      description { 'Hetzner S3-compatible object storage' }
    end

    trait :local_storage do
      service { 'local_storage' }
      description { 'Local file system storage' }
    end
  end
end
