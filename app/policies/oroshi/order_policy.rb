# frozen_string_literal: true

module Oroshi
  class OrderPolicy < ApplicationPolicy
    # Admin and Managerial have full access
    # Employee has read-only access (index, show)
    # Supplier has no direct order access

    def index?
      user.admin? || user.managerial? || user.employee?
    end

    def show?
      user.admin? || user.managerial? || user.employee?
    end

    def create?
      user.admin? || user.managerial?
    end

    def update?
      user.admin? || user.managerial?
    end

    def destroy?
      user.admin? || user.managerial?
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        if user.admin? || user.managerial? || user.employee?
          scope.all
        else
          scope.none
        end
      end
    end
  end
end
