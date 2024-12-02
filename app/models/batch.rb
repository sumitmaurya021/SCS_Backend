class Batch < ApplicationRecord
  has_many :batch_users
  has_many :users, through: :batch_users

  validates :name, presence: true
  validates :internship_type, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :number_of_students, numericality: { greater_than: 0 }

  # Method to assign users to the batch after creation
  def assign_users(user_ids)
    self.users << User.find(user_ids)
  end
end