namespace :orders do
  task set_shipped: :environment do
    Order.where(state: "closed").find_each do |order|
      CheckAndSetShippedOrderWorker.perform_async(order.id)
    end
  end
end