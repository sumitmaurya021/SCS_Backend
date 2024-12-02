class BatchUser < ApplicationRecord
  belongs_to :batch
  belongs_to :user

  validates :batch_id, presence: true
  validates :user_id, presence: true
end
