class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
         belongs_to :role


  # validations
  validates :email, presence: true, uniqueness: true, format: { with: Devise::email_regexp }
  validates :username, presence: true, uniqueness: true
  validates :student_name, presence: true, length: { in: 6..20 }
  validates :mobile_number, presence: true, length: { is: 10 }, numericality: { only_integer: true }
  validates :college_name, presence: true
  validates :enrollment_number, presence: true, length: { is: 10 }, numericality: { only_integer: true }
  validates :branch, presence: true
  validates :semester, presence: true
  validates :course, presence: true
  validates :internship_type, presence: true
  validates :internship_start_date, presence: true
  validates :internship_end_date, presence: true
  validates :password, presence: true





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

end
