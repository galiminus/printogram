class CheckAndSetCancelledOrderWorker
  include Sidekiq::Worker

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return if order.blank? || order.state != "in_production"

    response = JSON.parse(Pwinty.get_order(order))

    if response.try(:[], "data").try(:[], "status") == "Cancelled"
      order.update(state: "cancelled")

      RefundOrderWorker.perform_async(order.id)

      begin
        if order.customer.chat_reference.present?
          Telegram.bots[:order].send_message(chat_id: order.customer.chat_reference, text: "Your order <b>#{order.reference}</b> has been cancelled, you will be refunded in 2 to 3 business days.", parse_mode: "HTML")
        end
      rescue => error
        ExceptionNotifier.notify_exception(error)
      end
    end
  end
end
