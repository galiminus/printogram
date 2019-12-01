class AddEncryptedFieldsForShipping < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :country_code_ciphertext, :string
    add_column :orders, :address1_ciphertext, :string
    add_column :orders, :address2_ciphertext, :string
    add_column :orders, :address_town_or_city_ciphertext, :string
    add_column :orders, :state_or_county_ciphertext, :string
    add_column :orders, :postal_or_zip_code_ciphertext, :string
    add_column :orders, :customer_name_ciphertext, :string
  end
end
