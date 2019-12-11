class CheckAndSetShippedOrderWorker
  include Sidekiq::Worker

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return if order.blank? || order.state != "in_production"

    response = JSON.parse(Pwinty.get_order(order))

    if response.try(:[], "data").try(:[], "shippingInfo").try(:[], "shipments")&.first.try(:[], "shippedOn").present?
      order.update(state: "shipped")

      begin
        if order.customer.chat_reference.present?
          Telegram.bots[:order].send_message(chat_id: order.customer.chat_reference, text: "Your order <b>#{order.reference}</b> has successfully shipped.", parse_mode: "HTML")
        end
      rescue => error
        ExceptionNotifier.notify_exception(error)
      end
    end
  end
end
