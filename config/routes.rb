Rails.application.routes.draw do

  resources :announcements, only: [:index, :edit, :update]

  get 'faqs/reorder', to: 'faqs#reorder', as: :reorder_faq
  resources :faqs do
    member do
      patch :move_up
      patch :move_down
    end
  end
  resources :reports, only: [:index] do
    collection do
      get 'information_requests_report', to: 'reports#information_requests_report'
      get 'loan_requests_report', to: 'reports#loan_requests_report'
      get 'import_data_report', to: 'reports#import_data_report'
    end
  end

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

  resources :addresses, only: [:show, :edit, :update, :destroy, :new, :create, :index] do
    member do
      patch :set_primary
    end
  end

  get 'app_preference/:name/:global', to: 'app_preferences#delete_preference', as: :delete_preference
  get 'app_preferences/app_prefs', to: 'app_preferences#app_prefs', as: :app_prefs
  post 'app_preferences/app_prefs', to: 'app_preferences#save_app_prefs'
  get 'app_preferences/delete_image/:pref_id', to: 'app_preferences#delete_image', as: :delete_image_app_prefs
  resources :app_preferences

  resources :information_requests, only: [:new, :show]
  post "information_requests/send_information_request", to: "information_requests#send_information_request", as: :send_information_request
  get "information_requests/show_modal/:id", to: "information_requests#show_modal", as: :information_request_show_modal

  get "loan_requests/step_two", to: "loan_requests#step_two", as: :step_two
  get "loan_requests/step_three", to: "loan_requests#step_three", as: :step_three
  get "loan_requests/step_four", to: "loan_requests#step_four", as: :step_four
  get "loan_requests/step_five", to: "loan_requests#step_five", as: :step_five
  resources :loan_requests, only: [:new, :show]
  post "loan_requests/send_loan_request", to: "loan_requests#send_loan_request", as: :send_loan_request

  post "loan_requests/enable", to: "loan_requests#enable", as: :enable_loan_request
  post "loan_questions/enable_preview", to: "loan_questions#enable_preview", as: :preview_loan_questions_access
  post "faqs/enable_preview", to: "faqs#enable_preview", as: :preview_faqs_access
  post "collections/enable_preview", to: "collections#enable_preview", as: :preview_collections_access
  post "checkout/enable_preview", to: "checkout#enable_preview", as: :preview_checkout_access
  post "home/enable_preview", to: "home#enable_preview", as: :preview_about_access


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
  post "checkout/remove_preparation"
  post "checkout/save_for_later"
  post "checkout/move_back"
  post "checkout/remove_unavailable"
  post "checkout/remove_no_longer_available"

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
  get "delete_image/:id", to: "collections#delete_image", as: :collection_delete_image
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
