Rails.application.routes.draw do
  devise_for :users
  use_doorkeeper do
    skip_controllers :authorizations, :applications, :authorized_applications
  end

  namespace :api do
    namespace :v1 do
      resources :users, only: [:create, :show, :index, :destroy, :update] do
        collection do
          post 'login'
          delete 'logout'
          post 'forgot_password', to: 'users#forgot_password'
          post 'reset_password', to: 'users#reset_password'
        end
        member do
          post 'accept_user', to: 'users#accept_user'
          post 'reject_user', to: 'users#reject_user'
        end
      end
    end
  end
end
