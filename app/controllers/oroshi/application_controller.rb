# frozen_string_literal: true

class Oroshi::ApplicationController < ApplicationController
  include Pundit::Authorization
  helper :all

  def address_attributes
    %i[id default active name company country_id subregion_id postal_code city address1 address2]
  end

  def check_managerial
    return unless respond_to?(:current_user)
    return unless current_user
    return if current_user.admin? || current_user.managerial?

    authentication_notice
  end

  def authentication_notice
    flash[:notice] = t("common.messages.access_denied")
    redirect_to root_path, error: t("common.messages.access_denied")
  end
end
