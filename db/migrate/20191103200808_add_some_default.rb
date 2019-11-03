class AddSomeDefault < ActiveRecord::Migration[6.0]
  def change
    change_column :orders, :preferred_shipping_method, :string, default: "Budget"
    change_column :orders, :country_code, :string, default: "FR"
  end
end
