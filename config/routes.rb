Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  telegram_webhook Telegram::OrderController, :order

  resources :orders

  get '/privacy-policy', to: "orders#new", as: :privacy_policy
  get '/terms-and-conditions', to: "orders#new", as: :terms_and_conditions

  # get '/:token', to: "orders#edit", as: :checkout

  root to: "orders#new"
end
