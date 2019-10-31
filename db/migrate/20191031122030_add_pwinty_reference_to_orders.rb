class AddPwintyReferenceToOrders < ActiveRecord::Migration[6.0]
  def change
    add_column :orders, :pwinty_reference, :integer, index: true
  end
end
