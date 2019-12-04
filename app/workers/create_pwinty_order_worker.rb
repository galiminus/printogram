class CreatePwintyOrderWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5

  sidekiq_retries_exhausted do |msg, ex|
    order = Order.find_by(id: msg["args"].first)
    return if order.blank? || order.state != "ongoing"

    order.update(state: "error")

    RefundOrderWorker.perform_async(order.id)

    begin
      Telegram.bots[:order].send_message(chat_id: order.customer.chat_reference, text: "Your order <b>#{order.reference}</b> couldn't be completed, you will be refunded in 2 to 3 business days. We are sorry for the inconvenience.", parse_mode: "HTML")
    rescue => error
      ExceptionNotifier.notify_exception(error)
    end
  end

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return if order.blank? || order.state != "ongoing"

    if order.pwinty_reference.blank?
      response = Pwinty.create_order({
        merchantOrderId: order.id,
        recipientName: order.customer_name,
        countryCode: order.country_code,
        preferredShippingMethod: order.preferred_shipping_method,
        address1: order.address1,
        address2: order.address2,
        addressTownOrCity: order.address_town_or_city,
        stateOrCounty: order.state_or_county,
        postalOrZipCode: order.postal_or_zip_code
      })
      order.update(pwinty_reference: JSON.parse(response.body)["data"]["id"])
    end

    order.images.each do |image|
      if image.pwinty_reference.blank?
        image.generate_pwinty_image!

        response = Pwinty.create_image(order, {
          sku: image.product.sku,
          url: image.document.service_url,
          copies: 1,
          sizing: "Crop",
        })
        image.update(pwinty_reference: JSON.parse(response.body)["data"]["id"])
      end
    end

    Pwinty.update_order_status(order, { status: "Submitted" })

    order.update(state: "in_production")

    begin
      Telegram.bots[:order].send_message(chat_id: order.customer.chat_reference, text: "Your order <b>#{order.reference}</b> has been successfully sent to our partner for printing.", parse_mode: "HTML")
    rescue => error
      ExceptionNotifier.notify_exception(error)
    end
  end
end
