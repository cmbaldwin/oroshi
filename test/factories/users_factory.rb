# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:username) { |n| "user#{n}" }
    password { 'password123' }
    password_confirmation { 'password123' }
    role { :user }
    approved { true }
    confirmed_at { Time.current }

    trait :admin do
      role { :admin }
      admin { true }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end

    trait :unapproved do
      approved { false }
    end
  end
end
