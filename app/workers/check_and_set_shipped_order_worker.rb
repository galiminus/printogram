class CheckAndSetShippedOrderWorker
  include Sidekiq::Worker

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return if order.blank? || order.state != "closed"

    response = JSON.parse(Pwinty.get_order(order))

    if response["data"]["shippingInfo"]["shipments"].first["shippedOn"].present?
      order.update(state: "shipped")

      begin
        if order.chat_reference.present?
          Telegram.bots[:order].send_message(chat_id: order.customer.chat_reference, text: "Your order <b>#{order.reference}</b> was successfully shipped.", parse_mode: "HTML")
        end
      rescue => error
        ExceptionNotifier.notify_exception(error)
      end
    end
  end
end