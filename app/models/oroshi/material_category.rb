# frozen_string_literal: true

class Oroshi::MaterialCategory < ApplicationRecord
  # Callbacks
  include Oroshi::Activatable

  # Associations
  has_many :materials, class_name: "Oroshi::Material", dependent: :destroy

  # Validations
  validates :name, presence: true
end
