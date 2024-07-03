class Role < ApplicationRecord
  has_many :users

  # validations
  validates :name, presence: true
end
