# frozen_string_literal: true

class CreateOroshiOnboardingProgresses < ActiveRecord::Migration[8.1]
  def change
    create_table :oroshi_onboarding_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.datetime :completed_at
      t.datetime :skipped_at
      t.string :current_step
      t.jsonb :completed_steps, default: []

      t.timestamps
    end
  end
end
