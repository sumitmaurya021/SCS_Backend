class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
         belongs_to :role

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
