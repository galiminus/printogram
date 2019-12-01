class AddTelegramReferenceToCustomers < ActiveRecord::Migration[6.0]
  def change
    add_column :customers, :telegram_reference, :string

    Customer.find_each do |customer|
      customer.update(telegram_reference: customer.telegram_id)
    end
  end
end
