Rails.application.routes.draw do
  get "home/index"
  # ================= AUTH =================
  devise_for :users

  # ================= USER =================
  root "home#index"  
  get "/home", to: "home#home"  # <-- USER ke /

  resources :bookings, path: "booking"

  # ================= ADMIN =================
  namespace :admin do
    root "dashboard#index"          # /admin
    get "dashboard", to: "dashboard#index"

    resources :room_levels
    resources :facilities
    resources :rooms
    resources :bookings, only: [:index, :show] do
      patch :validate, on: :member
    end
  end

  # ================= HEALTH CHECK =================
  get "up" => "rails/health#show", as: :rails_health_check
end
