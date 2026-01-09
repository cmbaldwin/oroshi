# frozen_string_literal: true

FactoryBot.define do
  factory :credential do
    service { 'google_cloud_storage' }
    key_name { 'api_key' }
    value { "sk-test-#{SecureRandom.hex(32)}" }
    status { :active }
    notes { 'Test credential' }

    trait :with_user do
      association :user
    end

    trait :system_wide do
      user { nil }
    end

    trait :expired do
      status { :expired }
      expires_at { 1.day.ago }
    end

    trait :revoked do
      status { :revoked }
    end

    trait :expiring_soon do
      expires_at { 15.days.from_now }
    end

    trait :sendgrid do
      service { 'sendgrid' }
      key_name { 'api_username' }
      value { 'apikey' }
    end

    trait :rakuten do
      service { 'rakuten' }
      key_name { 'api_key' }
      value { "rak_#{SecureRandom.hex(20)}" }
    end

    trait :hetzner_storage do
      service { 'hetzner_object_storage' }
      key_name { 'access_key' }
      value { "htz_#{SecureRandom.hex(16)}" }
    end
  end
end
