class RemoveUnencryptedCustomerFields < ActiveRecord::Migration[6.0]
  def change
    remove_column :customers, :telegram_id, :integer
    remove_column :customers, :name, :string
    remove_column :customers, :username, :string
  end
end
