class BuildCartWorker
  include Sidekiq::Worker

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return if order.blank?

    Montage.create_cart(order) do |path|
      order.cart.attach({
        io: open(path),
        filename: "cart-#{order.id}.webp"
      })
    end
  end
end