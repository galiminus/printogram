class AddCurrencyAndFinalAmountToOrder < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :currency, :string, default: "USD"
    add_column :orders, :customer_name, :string
    add_column :orders, :final_price, :integer
  end
end
