# frozen_string_literal: true

class User < ApplicationRecord
  validates :username, presence: true, uniqueness: { case_sensitive: false }
  validates_format_of :username, with: /\A[a-zA-Z0-9_.]*\z/

  after_initialize :set_default_role, if: :new_record?

  enum :role, { user: 0, vip: 1, admin: 2, supplier: 3, employee: 4 }

  # Oroshi associations
  has_one :onboarding_progress, class_name: "Oroshi::OnboardingProgress", dependent: :destroy
  has_one :supplier, class_name: "Oroshi::Supplier", dependent: :destroy
  has_one :buyer, class_name: "Oroshi::Buyer", dependent: :destroy

  # Devise modules
  devise :database_authenticatable, :registerable, :confirmable,
         :recoverable, :rememberable, :trackable, :validatable,
         authentication_keys: [ :login ]

  attr_writer :login

  def login
    @login || username || email
  end

  def set_default_role
    self.role ||= :user
  end

  # Demo account check (used in layout for demo banner)
  def demo_account?
    false
  end

  # Allow login with either username or email
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if (login = conditions.delete(:login))
      where(conditions.to_h).where([ "lower(username) = :value OR lower(email) = :value",
                                    { value: login.downcase } ]).first
    elsif conditions.key?(:username) || conditions.key?(:email)
      where(conditions.to_h).first
    end
  end

  protected

  def confirmation_required?
    true
  end
end
