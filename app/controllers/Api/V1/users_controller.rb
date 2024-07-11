 require 'tempfile'
module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :doorkeeper_authorize!, only: [:create, :login, :forgot_password, :reset_password, :credentials, :generate_offer_letter]
      before_action :doorkeeper_authorize!, only: [:logout, :index, :show, :update, :destroy, :accept_user, :reject_user, :current_user]
      before_action :set_user, only: [:show, :update, :destroy]

      def index
        current_user = User.find_by(id: doorkeeper_token.resource_owner_id) if doorkeeper_token
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
              internship_start_date: user.internship_start_date.strftime('%d-%m-%Y'),
              internship_end_date: user.internship_end_date.strftime('%d-%m-%Y'),
              status: user.status,
              reference_number: user.reference_number,
              issue_date_of_letter: user.issue_date_of_letter.nil? ? nil : user.issue_date_of_letter.strftime('%d-%m-%Y'),
              internship_area: user.internship_area,
              created_at: user.created_at,
              updated_at: user.updated_at
            }
          end
          render json: { users: users, message: 'This is a list of all customers' }, status: :ok
        else
          render json: { error: 'You are not authorized to perform this action' }, status: :unauthorized
        end
      end

      def current_user
        if doorkeeper_token
          @current_user ||= User.find_by(id: doorkeeper_token.resource_owner_id)
        end

        if @current_user
          user_info = {
            id: @current_user.id,
            student_name: @current_user.student_name,
            username: @current_user.username,
            email: @current_user.email,
            role: @current_user.role.name,
            mobile_number: @current_user.mobile_number,
            college_name: @current_user.college_name,
            enrollment_number: @current_user.enrollment_number,
            branch: @current_user.branch,
            semester: @current_user.semester,
            course: @current_user.course,
            internship_type: @current_user.internship_type,
            internship_start_date: @current_user.internship_start_date.strftime('%d-%m-%Y'),
            internship_end_date: @current_user.internship_end_date.strftime('%d-%m-%Y'),
            status: @current_user.status,
            reference_number: @current_user.reference_number,
            issue_date_of_letter: @current_user.issue_date_of_letter.nil? ? nil : @current_user.issue_date_of_letter.strftime('%d-%m-%Y'),
            internship_area: @current_user.internship_area,
            created_at: @current_user.created_at,
            updated_at: @current_user.updated_at
          }
          render json: { user: user_info, message: 'Current User Fetched successfully' }, status: :ok
        else
          render json: { error: 'User not found' }, status: :not_found
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

          # Find the next available sequence number
          sequence_number_record = SequenceNumber.order(:number).last
          next_sequence_number = sequence_number_record ? sequence_number_record.number + 1 : 1
          SequenceNumber.create!(number: next_sequence_number)

          reference_number = "TSS/#{internship_type}/#{current_year}/#{next_sequence_number.to_s.rjust(3, '0')}"
          user.update!(status: "Approved", sequence_number: next_sequence_number, reference_number: reference_number, issue_date_of_letter: issue_date_of_letter)
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
        params.require(:user).permit(:email, :password, :username, :role_name, :student_name, :mobile_number, :college_name, :enrollment_number, :branch, :semester, :course, :internship_type, :internship_start_date, :internship_end_date, :internship_area )
      end

      def user_response(user, access_token)
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
            internshipship_type: user.internship_type,
            Internship_start_date: user.internship_start_date.strftime('%d-%m-%Y'),
            Internship_end_date: user.internship_end_date.strftime('%d-%m-%Y'),
            status: user.status,
            internship_area: user.internship_area.strftime('%d-%m-%Y'),
            created_at: access_token.created_at.to_time.to_i,
            access_token: access_token.token
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
