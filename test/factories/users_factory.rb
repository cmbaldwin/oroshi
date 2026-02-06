# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    password { "password123" }
    password_confirmation { "password123" }
    role { :vip }
    approved { true }
    confirmed_at { Time.current }

    # Skip Devise callbacks that require Warden mappings in system tests
    after(:build) do |user|
      user.skip_confirmation_notification!
    end

    # Create a skipped onboarding progress so tests don't redirect to onboarding
    after(:create) do |user|
      user.create_onboarding_progress!(skipped_at: Time.current) unless user.onboarding_progress
    end

    trait :admin do
      role { :admin }
      admin { true }
    end

    trait :vip do
      role { :vip }
    end

    trait :supplier do
      role { :supplier }
    end

    trait :employee do
      role { :employee }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :unapproved do
      approved { false }
    end
  end
end
