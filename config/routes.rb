Rails.application.routes.draw do
  devise_for :users

  namespace :admin do
    get 'home/index', to: 'home#index', as: 'home_index'
    get 'home/barriers', to: 'home#barriers', as: 'home_barriers'
    post '/upload_kmz', to: 'kmz#upload'
  end

  namespace :user do
    get 'home/index', to: 'home#index', as: 'home_index'
  end

  authenticated :admin do
    root to: 'admin/home#index', as: :authenticated_admin_root
  end

  authenticated :user do
    root to: 'user/home#index', as: :authenticated_user_root
  end

  unauthenticated do
    root to: 'user/home#index'
  end
end
