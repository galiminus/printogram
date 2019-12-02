class RemoveOldOrderFields < ActiveRecord::Migration[6.0]
  def change
    remove_column :orders, :country_code, :string
    remove_column :orders, :address1, :string
    remove_column :orders, :address2, :string
    remove_column :orders, :address_town_or_city, :string
    remove_column :orders, :state_or_county, :string
    remove_column :orders, :postal_or_zip_code, :string
    remove_column :orders, :customer_name, :string
  end
end
