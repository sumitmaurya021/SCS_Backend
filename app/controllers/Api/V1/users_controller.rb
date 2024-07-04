module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :doorkeeper_authorize!, only: [:create, :login, :forgot_password, :reset_password]
      before_action :doorkeeper_authorize!, only: [:logout, :index, :show, :update, :destroy]
      before_action :set_user, only: [:show, :update, :destroy]

      def index
        if current_user.is_admin?
          users = User.all.map do |user|
            {
              id: user.id,
              student_name: user.student_name,
              username: user.username,
              email: user.email,
              role: user.role.name,
              mobile_number: user.mobile_number,
              college_name: user.college_name,
              enrollment_number: user.enrollment_number,
              branch: user.branch,
              semester: user.semester,
              course: user.course,
              internship_type: user.internship_type,
              internship_start_date: user.internship_start_date,
              internship_end_date: user.internship_end_date
            }
          end
          render json: { users: users, message: 'This is a list of all users' }, status: :ok
        else
          render json: { error: 'You are not authorized to perform this action' }, status: :unauthorized
        end
      end


      def show
        render json: { user: @user, message: 'User Fetched successfully With Perticular ID' }, status: :ok
      end


      def create
        user = User.new(user_params)

        client_app = Doorkeeper::Application.find_by(uid: params[:client_id])
        return render(json: { error: 'Invalid client ID' }, status: :forbidden) unless client_app

        if user.save
          access_token = create_access_token(user, client_app)
          render json: { user: user_response(user, access_token), message: 'User created successfully' }, status: :created
        else
          render json: { error: user.errors.full_messages }, status: :unprocessable_entity
        end
      end


      def login
        user = User.find_by(username: params[:username])

        if user.nil?
          render json: { error: 'Invalid username' }, status: :unauthorized
        elsif user.valid_password?(params[:password])
          client_app = Doorkeeper::Application.find_by(uid: params[:client_id])
          if client_app
            access_token = create_access_token(user, client_app)
            render_login_response(user, access_token, 'Login successful')
          else
            render json: { error: 'Invalid client ID' }, status: :forbidden
          end
        else
          render json: { error: 'Invalid password' }, status: :unauthorized
        end
      end



      def logout
        current_token = Doorkeeper::AccessToken.find_by(token: params[:access_token])

        if current_token
          render_logout_response(current_token.destroy)
        else
          render_unauthorized_response('Invalid access token')
        end
      end


      def update
        if @user.update(user_params)
          render json: { message: 'User updated successfully' }, status: :ok
        else
          render json: { error: @user.errors.full_messages }, status: :unprocessable_entity
        end
      end


      def destroy
        if @user.destroy
          render json: { message: 'User deleted successfully' }, status: :ok
        else
          render json: { error: 'Failed to delete user' }, status: :unprocessable_entity
        end
      end

      def forgot_password

        binding.pry
        
        user = User.find_by(email: params[:email])
        if user
          otp = generate_otp
          user.update(otp: otp)
          UserMailer.send_otp(user).deliver_now
          render json: { message: 'OTP sent to your email' }, status: :ok
        else
          render json: { error: 'Email not found' }, status: :not_found
        end
      end


      def reset_password
        user = User.find_by(email: params[:email])
        if user && user.otp == params[:otp]
          if user.update(password: params[:new_password])
            user.update(otp: nil)
            render json: { message: 'Password reset successfully' }, status: :ok
          else
            render json: { error: user.errors.full_messages }, status: :unprocessable_entity
          end
        else
          render json: { error: 'Invalid OTP or OTP expired' }, status: :unauthorized
        end
      end


      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(:email, :password, :username, :role_name, :student_name, :mobile_number, :college_name, :enrollment_number, :branch, :semester, :course, :internship_type, :internship_start_date, :internship_end_date)
      end

      def user_response(user, access_token)
        {
          user: {
            id: user.id,
            student_name: user.student_name,
            username: user.username,
            email: user.email,
            role: user.role.name,
            mobile_number: user.mobile_number,
            college_name: user.college_name,
            enrollment_number: user.enrollment_number,
            branch: user.branch,
            semester: user.semester,
            course: user.course,
            internshipship_type: user.internship_type,
            Internship_start_date: user.internship_start_date,
            Internship_end_date: user.internship_end_date,
            created_at: access_token.created_at.to_time.to_i,
            access_token: access_token.token
          }
        }
      end

      def create_access_token(user, client_app)
        Doorkeeper::AccessToken.create!(
          resource_owner_id: user.id,
          application_id: client_app.id,
          refresh_token: generate_refresh_token,
          expires_in: Doorkeeper.configuration.access_token_expires_in.to_i,
          scopes: ''
        )
      end

      def render_login_response(user, access_token, message)
        user_data = {
          id: user.id,
          name: user.username,
          email: user.email,
          role: user.role.name,
          created_at: access_token.created_at.to_time.to_i,
          access_token: access_token.token
        }
        render json: { user: user_data, message: message }, status: :ok
      end

      def render_logout_response(destroyed)
        if destroyed
          render json: { message: 'Logout successful' }, status: :ok
        else
          render json: { error: 'Failed to destroy access token' }, status: :unprocessable_entity
        end
      end

      def render_unauthorized_response(message)
        render json: { error: message }, status: :unauthorized
      end

      def generate_refresh_token
        loop do
          token = SecureRandom.hex(32)
          break token unless Doorkeeper::AccessToken.exists?(refresh_token: token)
        end
      end

      def generate_otp
        rand(100000..999999).to_s
      end

    end
  end
end
