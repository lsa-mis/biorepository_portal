Rails.application.routes.draw do
  resources :identifications
  resources :preparations
  resources :items, only: [ :index, :show ]
  
  resources :collections do
    collection do
      post :import
    end
    member do
      match 'search' => 'collections#search', via: [:get, :post]
    end
  end
  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks", sessions: "users/sessions"} do
    delete 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session
  end
  
  get "home/index"
  get "home/about", to: "home#about", as: :about
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development? || Rails.env.staging?

end
