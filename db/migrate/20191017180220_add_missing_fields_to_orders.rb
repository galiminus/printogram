class AddMissingFieldsToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :address1, :string
    add_column :orders, :address2, :string
    add_column :orders, :address_town_or_city, :string
    add_column :orders, :state_or_county, :string
    add_column :orders, :postal_or_zip_code, :string
    add_column :orders, :preferred_shipping_method, :string
  end
end
