class AddClosedAtToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :closed_at, :datetime
  end
end
