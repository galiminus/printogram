namespace :orders do
  task set_shipped: :environment do
    Order.where(state: "in_production").find_each do |order|
      CheckAndSetShippedOrderWorker.perform_async(order.id)
    end
  end

  task set_cancelled: :environment do
    Order.where(state: "in_production").find_each do |order|
      CheckAndSetCancelledOrderWorker.perform_async(order.id)
    end
  end
end