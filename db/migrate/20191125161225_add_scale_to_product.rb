class AddScaleToProduct < ActiveRecord::Migration[6.0]
  def change
    add_column :products, :scale, :float
    Product.update_all(scale: 0.75)
  end
end
