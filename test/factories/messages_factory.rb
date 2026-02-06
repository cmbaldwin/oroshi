# frozen_string_literal: true

FactoryBot.define do
  factory :message do
    state { nil }
    message { nil }
    data { {} }
  end
end
