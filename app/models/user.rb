class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
         belongs_to :role

        #  Validations
         validates :email, presence: true, uniqueness: true
         validates :password, presence: true
         validates :username, presence: true, uniqueness: true


         private

         def is_admin?
           role.name == "admin"
         end

         def is_user?
           role.name == "user"
         end
end
