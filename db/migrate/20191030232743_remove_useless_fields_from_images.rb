class RemoveUselessFieldsFromImages < ActiveRecord::Migration[6.0]
  def change
    remove_column :images, :sku
    remove_column :images, :md5_hash
    remove_column :images, :copies
    remove_column :images, :sizing
    remove_column :images, :product_id
  end
end
