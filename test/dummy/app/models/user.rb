class User < ApplicationRecord
  # User roles: vip, admin, supplier, employee
  enum :role, { vip: 1, admin: 2, supplier: 3, employee: 4 }

  # Oroshi associations
  has_one :onboarding_progress, class_name: "Oroshi::OnboardingProgress", dependent: :destroy
  has_one :supplier, class_name: "Oroshi::Supplier", dependent: :destroy
  has_one :buyer, class_name: "Oroshi::Buyer", dependent: :destroy

  # Devise modules
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         authentication_keys: [ :login ]

  attr_accessor :login

  # Allow login with either username or email
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where([ "lower(username) = :value OR lower(email) = :value", { value: login.downcase } ]).first
    elsif conditions.has_key?(:username) || conditions.has_key?(:email)
      where(conditions.to_h).first
    end
  end
end
