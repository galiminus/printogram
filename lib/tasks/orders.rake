namespace :orders do
  task :expire do
    Order.where(state: "draft").find_each do |order|
      
    end
  end
end