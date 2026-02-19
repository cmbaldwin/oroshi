# frozen_string_literal: true

class Oroshi::ApplicationController < ApplicationController
  helper OroshiHelper

  def address_attributes
    %i[id default active name company country_id subregion_id postal_code city address1 address2]
  end

  def check_managerial
    return if current_user.admin? || current_user.managerial?

    authentication_notice
  end

  def authentication_notice
    flash[:notice] = "\u305D\u306E\u30DA\u30FC\u30B8\u306F\u30A2\u30AF\u30BB\u30B9\u3067\u304D\u307E\u305B\u3093\u3002"
    redirect_to root_path, error: "\u305D\u306E\u30DA\u30FC\u30B8\u306F\u30A2\u30AF\u30BB\u30B9\u3067\u304D\u307E\u305B\u3093\u3002"
  end
end
