Rails.application.routes.draw do

  get 'app_preference/:name', to: 'app_preferences#delete_preference', as: :delete_preference
  get 'app_preferences/app_prefs', to: 'app_preferences#app_prefs', as: :app_prefs
  post 'app_preferences/app_prefs/', to: 'app_preferences#save_app_prefs'
  resources :app_preferences
  
  get "requests/information_request", to: "requests#information_request", as: :information_request
  post "requests/send_information_request", to: "requests#send_information_request", as: :send_information_request
  get "loan_questions/preview", to: "loan_questions#preview", as: :preview_loan_questions
  resources :loan_questions
  get "checkout", to: "checkout#show"
  post "checkout/add"
  post "checkout/remove"
  resources :identifications
  resources :preparations
  resources :items, only: [ :index, :show ] do
    collection do
      match 'search' => 'items#search', via: [:get, :post]
    end
  end
  
  resources :collections do
    collection do
      post :import
    end

    member do
      match 'search' => 'collections#search', via: [:get, :post]
    end

    resources :collection_questions, module: :collections do
      collection do
        get :preview
      end
    end
  end
  get "collection/:id/items", to: "collections#items", as: :collection_items
  get 'add_item_to_checkout/:item_id', to: 'collections#add_item_to_checkout', as: :add_item_to_checkout

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
