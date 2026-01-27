# frozen_string_literal: true

module Oroshi
  class OrderPolicy < ApplicationPolicy
    # Admin and VIP have full access
    # Employee has read-only access (index, show)
    # Supplier has no direct order access

    def index?
      user.admin? || user.vip? || user.employee?
    end

    def show?
      user.admin? || user.vip? || user.employee?
    end

    def create?
      user.admin? || user.vip?
    end

    def update?
      user.admin? || user.vip?
    end

    def destroy?
      user.admin? || user.vip?
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        if user.admin? || user.vip? || user.employee?
          scope.all
        else
          scope.none
        end
      end
    end
  end
end
