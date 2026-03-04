# frozen_string_literal: true

module Oroshi
  class SupplyPolicy < ApplicationPolicy
    # Admin and Managerial have full access
    # Employee has read-only access
    # Supplier can only access their own supplies

    def index?
      user.admin? || user.managerial? || user.employee? || user.supplier?
    end

    def show?
      user.admin? || user.managerial? || user.employee? || owns_supply?
    end

    def create?
      user.admin? || user.managerial? || owns_supplier_organization?
    end

    def update?
      user.admin? || user.managerial? || owns_supply?
    end

    def destroy?
      user.admin? || user.managerial?
    end

    class Scope < ApplicationPolicy::Scope
      def resolve
        if user.admin? || user.managerial? || user.employee?
          scope.all
        elsif user.supplier?
          # Only supplies belonging to this supplier user's supplier record
          supplier_record = Oroshi::Supplier.find_by(user: user)
          supplier_record ? scope.where(supplier: supplier_record) : scope.none
        else
          scope.none
        end
      end
    end

    private

    def owns_supply?
      return false unless user.supplier?
      record.supplier&.user_id == user.id
    end

    def owns_supplier_organization?
      return false unless user.supplier?
      supplier_record = Oroshi::Supplier.find_by(user: user)
      supplier_record.present?
    end
  end
end
