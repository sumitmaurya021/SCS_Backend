class User < ApplicationRecord
  attr_accessor :admin_updating

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  belongs_to :role

  # validations
  validates :email, presence: true, uniqueness: true, format: { with: Devise::email_regexp }
  validates :username, presence: true, uniqueness: true
  validates :student_name, presence: true, length: { in: 6..20 }
  validates :mobile_number, presence: true, length: { is: 10 }, numericality: { only_integer: true }
  validates :college_name, presence: true
  validates :enrollment_number, presence: true
  validates :branch, presence: true
  validates :semester, presence: true
  validates :course, presence: true
  validates :internship_type, presence: true
  validates :internship_start_date, presence: true
  validates :internship_end_date, presence: true
  validates :internship_area, presence: true

  validate :password_presence

  after_initialize :set_default_role, if: :new_record?

  def set_default_role
    self.role ||= Role.find_by(name: 'customer')
  end

  # Methods for roles
  def is_admin?
    role.name == "admin"
  end

  def is_user?
    role.name == "user"
  end

  private

  def password_presence
    if admin_updating
      return
    end

    if new_record? || !password.blank?
      errors.add(:password, "can't be blank") if password.blank?
    end
  end
end
