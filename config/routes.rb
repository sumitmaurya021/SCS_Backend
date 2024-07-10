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
          get 'generate_offer_letter', to: 'users#generate_offer_letter', format: :pdf
          post 'accept_user', to: 'users#accept_user'
          post 'reject_user', to: 'users#reject_user'
          get 'preview_offer_letter', to: 'users#preview_offer_letter'
        end
      end

      get "credentials", to: "users#credentials"
      get "current_user", to: "users#current_user"
    end
  end
end
