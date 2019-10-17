class AddMissingFieldsToImages < ActiveRecord::Migration[6.0]
  def change
    add_column :images, :sku, :string
    add_column :images, :md5_hash, :string
    add_column :images, :copies, :integer
    add_column :images, :sizing, :string
  end
end
