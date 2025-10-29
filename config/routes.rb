Rails.application.routes.draw do
  resources :shipments, only: [:index, :show] do
    member do
      post :start_simulation
      post :stop_simulation
      post :simulate_update
    end
  end
  
  get 'shipments/dashboard', to: 'shipments#dashboard'
  get 'simulator', to: 'simulator#index'
  post 'simulator/start_all', to: 'simulator#start_all'
  post 'simulator/stop_all', to: 'simulator#stop_all'

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "shipments#index"
end
