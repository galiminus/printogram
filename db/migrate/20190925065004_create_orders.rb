class CreateOrders < ActiveRecord::Migration[6.0]
  def change
    create_table :orders do |t|
      t.string :country_code
      t.string :recipient_name
      t.string :state, default: :draft, index: true
      t.belongs_to :customer

      t.timestamps
    end
  end
end
