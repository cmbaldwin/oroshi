# frozen_string_literal: true

class Oroshi::ApplicationController < ApplicationController
  include Pundit::Authorization

  # Require authentication for all engine actions
  # This ensures the engine works regardless of parent app configuration
  before_action :authenticate_user!

  helper OroshiHelper
  helper Oroshi::UrlHelper

  def address_attributes
    %i[id default active name company country_id subregion_id postal_code city address1 address2]
  end

  def check_vip
    return unless respond_to?(:current_user)
    return unless current_user
    return if current_user.admin? || current_user.vip?

    authentication_notice
  end

  def authentication_notice
    message = t('common.messages.access_denied')
    flash[:notice] = message
    redirect_to root_path, error: message
  end
end
