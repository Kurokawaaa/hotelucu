Rails.application.routes.draw do
  get "home/index"
  # ================= AUTH =================
  devise_for :users

  # ================= USER =================
  root "home#index"
  get "/home", to: "home#home"

  resources :bookings, path: "booking" do
    get :availability, on: :collection
    post :snap_token, on: :member
    post :confirm_payment, on: :member
  end

  post "/midtrans/notification", to: "midtrans#notification"

  # ================= ADMIN =================
  namespace :admin do
    root "dashboard#index"
    get "dashboard", to: "dashboard#index"

    resources :room_levels
    resources :facilities
    resources :rooms
    resources :bookings, only: [:index, :show, :update, :destroy] do
      get :new_reservation, on: :collection
      post :create_reservation, on: :collection
      patch :checkout, on: :member
      get :history, on: :collection
      patch :validate, on: :member
    end
  end

  # ================= HEALTH CHECK =================
  get "up" => "rails/health#show", as: :rails_health_check
end
