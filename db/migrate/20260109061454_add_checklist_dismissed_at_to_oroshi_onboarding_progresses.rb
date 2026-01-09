class AddChecklistDismissedAtToOroshiOnboardingProgresses < ActiveRecord::Migration[8.1]
  def change
    add_column :oroshi_onboarding_progresses, :checklist_dismissed_at, :datetime
  end
end
