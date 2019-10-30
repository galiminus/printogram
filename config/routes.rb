Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  telegram_webhook Telegram::OrderController, :order

  resources :orders

  get '/privacy-policy', to: "pages#privacy_policy", as: :privacy_policy
  get '/terms-and-conditions', to: "pages#terms_and_conditions", as: :terms_and_conditions

  # get '/:token', to: "orders#edit", as: :checkout

  root to: "orders#new"
end
