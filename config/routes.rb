Rails.application.routes.draw do
  devise_for :users

  namespace :admin do
    get 'home/index', to: 'home#index', as: 'home_index'
    get 'home/barriers', to: 'home#barriers', as: 'home_barriers'
    get 'home/job_sheet', to: 'home#job_sheet', as: 'job_sheet'
    get 'home/route_setting', to: 'home#route_setting', as: 'route_setting'
    get 'home/fetch_regions', to: 'home#fetch_regions', as: 'fetch_regions'
    post 'home/selected_regions', to: 'home#selected_regions', as: 'selected_regions'
    get 'home/geocode', to: 'home#geocode', as: 'geocode'
    post '/upload_kmz', to: 'kmz#upload'
    post '/barriers', to: 'barriers#create', format: :js
    get '/barriers', to: 'barriers#index', as: 'barrier_index'
    delete '/barriers', to: 'barriers#destroy', as: 'destroy'
    post '/job_sheets', to: 'job_sheets#create'
    post '/generate_pdf', to: 'job_sheets#generate_pdf'
    post 'home/get_directions', to: 'home#get_directions'
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
