# frozen_string_literal: true

module Oroshi
  class LegalController < ApplicationController
    skip_before_action :maybe_authenticate_user, only: [ :privacy_policy, :terms_of_service ], raise: false
    skip_before_action :authenticate_user!, only: [ :privacy_policy, :terms_of_service ], raise: false

    def privacy_policy
      render layout: "legal"
    end

    def terms_of_service
      render layout: "legal"
    end
  end
end
