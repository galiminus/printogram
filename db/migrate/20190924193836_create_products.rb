class CreateProducts < ActiveRecord::Migration[6.0]
  def change
    create_table :products do |t|
      t.string :name
      t.string :dimensions
      t.string :sku
      t.integer :order

      t.timestamps
    end
  end
end
