class RefundOrderWorker
  include Sidekiq::Worker

  def perform(order_id)
    order = Order.find_by(id: order_id)
    return if order.blank? || order.state != "error" || order.provider_payment_charge_reference.blank?

    Stripe::Refund.create({ charge: order.provider_payment_charge_reference })

    order.update(state: "refunded")
  end
end