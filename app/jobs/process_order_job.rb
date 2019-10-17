class ProcessOrderJob < ApplicationJob
  queue_as :default

  def perform(order)
    # Create order
    Pwinty.create_order(order.attributes)

    # Add all images
    order.images.find_each do |image|
      Pwinty.create_image(order.id, image.attributes)
    end

    # Check validity
    Pwinty.check_order_validity(order)

    # Submit

  end
end
