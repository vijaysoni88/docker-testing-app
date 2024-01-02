Rails.application.routes.draw do
  devise_for :users

  namespace :admin do
    get 'home/index', to: 'home#index', as: 'home_index'
    get 'home/barriers', to: 'home#barriers', as: 'home_barriers'
    get 'home/route_setting', to: 'home#route_setting', as: 'route_setting'
    get 'home/fetch_regions', to: 'home#fetch_regions', as: 'fetch_regions'
    get 'home/geocode', to: 'home#geocode', as: 'geocode'
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
