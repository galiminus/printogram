class BuildCartJob < ApplicationJob
  queue_as :default

  def perform(order)
    Montage.create_cart(order) do |path|
      order.cart.attach({
        io: open(path),
        filename: "cart-#{order.id}.webp"
      })
    end
  end
end
