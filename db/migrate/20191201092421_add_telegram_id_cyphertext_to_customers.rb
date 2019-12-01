class AddTelegramIdCyphertextToCustomers < ActiveRecord::Migration[6.0]
  def change
    add_column :customers, :telegram_id_ciphertext, :string
    add_column :customers, :name_ciphertext, :string
    add_column :customers, :username_ciphertext, :string

    remove_column :customers, :country_code, :string
  end
end
