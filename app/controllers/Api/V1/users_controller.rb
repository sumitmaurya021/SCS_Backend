# app/controllers/api/v1/users_controller.rb
module Api
  module V1
    class UsersController < ApplicationController
      skip_before_action :doorkeeper_authorize!, only: [:create, :login]
      before_action :doorkeeper_authorize!, only: [:logout, :index, :show, :update, :destroy]
      before_action :set_user, only: [:show, :update, :destroy]


      def index
        if current_user.role.name == 'admin'
          users = User.all.map { |user| { id: user.id, username: user.username, email: user.email, role: user.role.name } }
          render json: { users: users, message: 'This is a list of all users' }, status: :ok
          else
            render json: { error: 'You are not authorized to perform this action' }, status: :unauthorized
        end
      end

      def show
        render json: { user: @user, message: 'User retrieved successfully' }, status: :ok
      end

      def create
        user = User.new(user_params)
        role = Role.find_by(name: params[:user][:role_name].downcase)

        if role.nil?
          render json: { error: 'Role not found' }, status: :unprocessable_entity
        end
        user.role = role
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

        if user&.valid_password?(params[:password])
          client_app = Doorkeeper::Application.find_by(uid: params[:client_id])
          access_token = create_access_token(user, client_app)
          render_login_response(user, access_token, 'Login successful')
        else
          render json: { error: 'Invalid username or password' }, status: :unauthorized
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

      private

      def set_user
        @user = User.find(params[:id])
      end

      def user_params
        params.require(:user).permit(:email, :password, :username)
      end

      def user_response(user, access_token)
        {
          user: {
            id: user.id,
            name: user.username,
            email: user.email,
            role: user.role.name,
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

    end
  end
end
