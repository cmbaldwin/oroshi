# frozen_string_literal: true

module Oroshi
  class ExportPolicy < ApplicationPolicy
    # Export access mirrors order read access:
    # Admin, VIP, and Employee can export data
    def create?
      user.admin? || user.vip? || user.employee?
    end
  end
end
