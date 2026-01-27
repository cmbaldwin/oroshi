# frozen_string_literal: true

module Oroshi
  class SupplierPolicy < ApplicationPolicy
    # Admin and VIP have full access
    # Employee has read-only access
    # Supplier can only access their own supplier record

    def index?
      user.admin? || user.vip? || user.employee? || user.supplier?
    end

    def show?
      user.admin? || user.vip? || user.employee? || owns_supplier?
    end

    def create?
      user.admin? || user.vip?
    end

    def update?
      user.admin? || user.vip? || owns_supplier?
    end

    def destroy?
      user.admin? || user.vip?
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        if user.admin? || user.vip? || user.employee?
          scope.all
        elsif user.supplier?
          # Only the supplier record belonging to this user
          scope.where(user: user)
        else
          scope.none
        end
      end
    end

    private

    def owns_supplier?
      return false unless user.supplier?
      record.user_id == user.id
    end
  end
end
