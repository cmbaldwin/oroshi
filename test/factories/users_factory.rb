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
