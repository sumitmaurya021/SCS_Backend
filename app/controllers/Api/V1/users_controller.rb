 require 'tempfile'
module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :doorkeeper_authorize!, only: [:create, :login, :forgot_password, :reset_password, :credentials, :generate_offer_letter]
      before_action :doorkeeper_authorize!, only: [:logout, :index, :show, :update, :destroy, :accept_user, :reject_user]
      before_action :set_user, only: [:show, :update, :destroy]

      def index
        if current_user.is_admin?
          customer_role = Role.find_by(name: 'customer')
          users = User.includes(:role).where(role: customer_role).map do |user|
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
              internship_end_date: user.internship_end_date,
              status: user.status,
              reference_number: user.reference_number
            }
          end
          render json: { users: users, message: 'This is a list of all customers' }, status: :ok
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

      def accept_user
        user = User.find_by(id: params[:id])
        if user
          current_year = Date.today.year
          issue_date_of_letter = Date.today
          internship_type = user.internship_type

          # Find all existing reference numbers for the current year and internship type
          existing_reference_numbers = User.where(internship_type: internship_type, status: 'Approved')
                                           .where("reference_number LIKE ?", "TSS/#{internship_type}/#{current_year}/%")
                                           .pluck(:reference_number)

          # Extract the sequence numbers from the existing reference numbers
          existing_sequence_numbers = existing_reference_numbers.map { |ref| ref.split('/').last.to_i }

          # Initialize the sequence number
          sequence_number = 1

          # Find the next available sequence number
          loop do
            break unless existing_sequence_numbers.include?(sequence_number)
            sequence_number += 1
          end

          reference_number = "TSS/#{internship_type}/#{current_year}/#{sequence_number.to_s.rjust(3, '0')}"
          user.update!(status: "Approved", reference_number: reference_number, issue_date_of_letter: issue_date_of_letter)
          render json: { message: 'User Approved successfully', user: user }, status: :ok
        else
          render json: { error: 'User not found' }, status: :not_found
        end
      end


      def reject_user
        user = User.find_by(id: params[:id])

        if user
          user.update!(status: "Rejected")
          render json: { message: 'User Rejected successfully', user: user }, status: :ok
        else
          render json: { error: 'User not found' }, status: :not_found
        end
      end

      def credentials
        client_id = Doorkeeper::Application.last.uid
        render json: { client_id: client_id, message: 'Client ID Fetched Successfully' }, status: :ok
      end

      def generate_offer_letter
        @user = User.find(params[:id])

        UserMailer.send_offer_letter(@user).deliver_now

        render json: { message: 'Offer letter has been sent to the user via email.' }, status: :ok
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
