class Oroshi::OnboardingController < ApplicationController
  layout "onboarding"

  before_action :authenticate_user!
  before_action :find_or_create_progress
  before_action :set_step, only: [ :show, :update ]

  # Ordered onboarding steps grouped by phase
  STEPS = {
    foundation: %w[welcome company_info],
    setup: %w[suppliers products inventory],
    configuration: %w[shipping notifications],
    completion: %w[review]
  }.freeze

  ALL_STEPS = STEPS.values.flatten.freeze

  def index
    # Redirect to current incomplete step or first step
    if @progress.current_step.present? && ALL_STEPS.include?(@progress.current_step)
      redirect_to oroshi_onboarding_path(@progress.current_step)
    else
      redirect_to oroshi_onboarding_path(ALL_STEPS.first)
    end
  end

  def show
    # Render the step form
  end

  def update
    # Mark step complete and redirect to next
    @progress.mark_step_complete!(@step)
    @progress.update!(current_step: next_step)

    if next_step
      redirect_to oroshi_onboarding_path(next_step), notice: "Step completed!"
    else
      # All steps complete
      @progress.update!(completed_at: Time.current)
      redirect_to oroshi_root_path, notice: "Onboarding complete!"
    end
  end

  def skip
    @progress.update!(skipped_at: Time.current)
    redirect_to oroshi_root_path, notice: "Onboarding skipped. You can resume anytime."
  end

  def resume
    @progress.update!(skipped_at: nil)
    redirect_to oroshi_onboarding_index_path, notice: "Resuming onboarding..."
  end

  private

  def find_or_create_progress
    @progress = current_user.onboarding_progress || current_user.create_onboarding_progress!
  end

  def set_step
    @step = params[:id]
    redirect_to oroshi_onboarding_index_path, alert: "Invalid step" unless ALL_STEPS.include?(@step)
  end

  def next_step
    current_index = ALL_STEPS.index(@step)
    ALL_STEPS[current_index + 1] if current_index
  end
end
