# frozen_string_literal: true

FactoryBot.define do
  factory :onboarding_progress, class: "Oroshi::OnboardingProgress" do
    association :user
    current_step { "welcome" }
    completed_steps { [] }
    completed_at { nil }
    skipped_at { nil }

    trait :completed do
      completed_at { Time.current }
      completed_steps { Oroshi::OnboardingController::ALL_STEPS }
    end

    trait :skipped do
      skipped_at { Time.current }
    end

    trait :in_progress do
      current_step { "company_info" }
      completed_steps { [ "welcome" ] }
    end
  end
end
