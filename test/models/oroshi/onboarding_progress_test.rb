# frozen_string_literal: true

require 'test_helper'

module Oroshi
  class OnboardingProgressTest < ActiveSupport::TestCase
    setup do
      @user = create(:user)
      @progress = Oroshi::OnboardingProgress.create!(
        user: @user,
        current_step: 'welcome',
        completed_steps: []
      )
    end

    test 'belongs to user' do
      assert_instance_of User, @progress.user
    end

    test 'completed_steps defaults to empty array' do
      progress = Oroshi::OnboardingProgress.create!(user: create(:user))
      assert_equal [], progress.completed_steps
    end

    test 'completed? returns false when completed_at is nil' do
      assert_not @progress.completed?
    end

    test 'completed? returns true when completed_at is set' do
      @progress.update!(completed_at: Time.current)
      assert @progress.completed?
    end

    test 'skipped? returns false when skipped_at is nil' do
      assert_not @progress.skipped?
    end

    test 'skipped? returns true when skipped_at is set' do
      @progress.update!(skipped_at: Time.current)
      assert @progress.skipped?
    end

    test 'step_completed? returns false for incomplete step' do
      assert_not @progress.step_completed?('company_info')
    end

    test 'step_completed? returns true for completed step' do
      @progress.update!(completed_steps: ['welcome'])
      assert @progress.step_completed?('welcome')
    end

    test 'step_completed? handles string and symbol arguments' do
      @progress.update!(completed_steps: ['welcome'])
      assert @progress.step_completed?('welcome')
      assert @progress.step_completed?(:welcome)
    end

    test 'mark_step_complete! adds step to completed_steps' do
      @progress.mark_step_complete!('welcome')
      assert_includes @progress.completed_steps, 'welcome'
    end

    test 'mark_step_complete! is idempotent' do
      @progress.mark_step_complete!('welcome')
      @progress.mark_step_complete!('welcome')
      assert_equal ['welcome'], @progress.completed_steps
    end

    test 'mark_step_complete! persists to database' do
      @progress.mark_step_complete!('company_info')
      @progress.reload
      assert_includes @progress.completed_steps, 'company_info'
    end

    test 'mark_step_complete! preserves existing steps' do
      @progress.update!(completed_steps: ['welcome'])
      @progress.mark_step_complete!('company_info')
      assert_equal %w[welcome company_info], @progress.completed_steps
    end
  end
end
