class Oroshi::OnboardingProgress < ApplicationRecord
  belongs_to :user

  # Ensure completed_steps is always an array
  attribute :completed_steps, :jsonb, default: []

  # Check if onboarding is completed
  def completed?
    completed_at.present?
  end

  # Check if onboarding was skipped
  def skipped?
    skipped_at.present?
  end

  # Check if checklist was dismissed
  def checklist_dismissed?
    checklist_dismissed_at.present?
  end

  # Check if a specific step has been completed
  def step_completed?(step_name)
    completed_steps.include?(step_name.to_s)
  end

  # Mark a step as complete
  def mark_step_complete!(step_name)
    return if step_completed?(step_name)

    self.completed_steps = completed_steps + [ step_name.to_s ]
    save!
  end
end
