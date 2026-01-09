# frozen_string_literal: true

class LegalController < ApplicationController
  skip_before_action :authenticate_user!, only: [:privacy_policy, :terms_of_service]

  def privacy_policy
    render layout: "legal"
  end

  def terms_of_service
    render layout: "legal"
  end
end
