class RemoveRecipientNameFromOrders < ActiveRecord::Migration[6.0]
  def change
    remove_column :orders, :recipient_name, :string
  end
end
