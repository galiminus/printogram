class AddTelegramAndStripeChargeReference < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :telegram_payment_charge_reference, :string, index: true
    add_column :orders, :provider_payment_charge_reference, :string, index: true
  end
end
