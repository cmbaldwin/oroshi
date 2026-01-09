# frozen_string_literal: true

class Oroshi::ApplicationController < ApplicationController
  helper OroshiHelper

  def address_attributes
    %i[id default active name company country_id subregion_id postal_code city address1 address2]
  end
end
