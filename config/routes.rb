Rails.application.routes.draw do

  resources :announcements, only: [:index, :edit, :update]

  get 'faqs/reorder', to: 'faqs#reorder', as: :reorder_faq
  resources :faqs do
    member do
      patch :move_up
      patch :move_down
    end
  end
  # get "profile/show"
  # get "profile/edit"
  # get "profile/update"

  resource :profile, only: [:show, :edit, :update] do
    get :show_loan_questions
    get :edit_loan_questions          # profile_loan_questions_path
    patch :update_loan_questions # profile_update_loan_questions_path
    get "profile_info", to: "profiles#profile_info", as: :profile_info
  end
  get 'profile/collections_questions', to: 'profiles#show_collections_questions', as: 'show_collections_questions_profile'
  get 'profile/collection_questions/:id', to: 'profiles#collection_questions', as: 'collection_questions_profile'
  patch 'profile/collection_questions/:id', to: 'profiles#update_collection_questions', as: 'update_collection_questions_profile'

  resources :users, only: [:edit, :update]

  get 'app_preference/:name', to: 'app_preferences#delete_preference', as: :delete_preference
  get 'app_preferences/app_prefs', to: 'app_preferences#app_prefs', as: :app_prefs
  post 'app_preferences/app_prefs', to: 'app_preferences#save_app_prefs'
  resources :app_preferences
  
  get "requests/information_request", to: "requests#information_request", as: :information_request
  post "requests/send_information_request", to: "requests#send_information_request", as: :send_information_request
  get "requests/show_information_request/:id", to: "requests#show_information_request", as: :show_information_request
  get "requests/loan_request", to: "requests#loan_request", as: :loan_request
  post "requests/send_loan_request", to: "requests#send_loan_request", as: :send_loan_request

  patch "update_loan_answer/:id", to: "loan_answers#update", as: :update_loan_answer
  get "edit_loan_answer/:id", to: "loan_answers#edit", as: :edit_loan_answer

  get "profile/edit_field/:field", to: "profiles#edit_field", as: :edit_user_field
  patch "profile/update_field/:field", to: "profiles#update_field", as: :update_user_field

  get "loan_questions/preview", to: "loan_questions#preview", as: :preview_loan_questions
  resources :loan_questions do
    member do
      patch :move_up
      patch :move_down
    end
  end
  get "checkout", to: "checkout#show"
  post "checkout/add"
  post "checkout/change"
  post "checkout/remove"
  post "checkout/save_for_later"
  post "checkout/move_back"

  get 'export_to_csv', to: 'items#export_to_csv', as: :export_to_csv
  resources :items, only: [ :index, :show ] do
    collection do
      match 'quick_search' => 'items#quick_search', via: [:get, :post]
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
      member do
        patch :move_up
        patch :move_down
      end
    end
    resources :collection_answers, module: :collections, only: [:edit, :update]

  end
  get "collection/:id/items", to: "collections#items", as: :collection_items
  get 'add_item_to_checkout/:item_id', to: 'collections#add_item_to_checkout', as: :add_item_to_checkout

  devise_for :users, controllers: {omniauth_callbacks: "users/omniauth_callbacks", sessions: "users/sessions"} do
    delete 'sign_out', :to => 'users/sessions#destroy', :as => :destroy_user_session
  end
  
  get "home/about", to: "home#about", as: :about
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#about"

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development? || Rails.env.staging?

end
