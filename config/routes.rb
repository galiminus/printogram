Rails.application.routes.draw do
  telegram_webhook Telegram::OrderController, :order
end
