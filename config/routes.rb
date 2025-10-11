Rails.application.routes.draw do
  namespace :admin do
    resources :stores, only: [ :index ] do
      collection do
        get :select
      end

      member do
        post :add_operator
        delete :remove_operator
      end

      resources :udon_shares, only: [ :new, :create ]
    end

    resources :udon_shares, only: [ :destroy ]
  end

  resources :passwords, param: :token
  resources :measurements do
    member do
      get :status
      post :respond
    end
  end

  resources :stores

  if Rails.env.production?
    resources :users, only: [ :new, :create ]
    resources :reviews, only: [ :index, :new, :create ]
  else
    resources :reviews, only: [ :index, :new, :create ]
    resources :users
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  get "signup", to: "users#new"
  get "signin", to: "sessions#new"
  post "signin", to: "sessions#create"
  delete "signout", to: "sessions#destroy"

  # Defines the root path route ("/")
  root "home#index"
end
