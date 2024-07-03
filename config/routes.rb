Rails.application.routes.draw do
  devise_for :users
  use_doorkeeper do
    skip_controllers :authorizations, :applications, :authorized_applications
  end

  namespace :api do
    namespace :v1 do
      resources :users, only: [:create, :show, :index] do
        collection do
          post 'login'
          delete 'logout'
        end
      end
    end
  end
end
