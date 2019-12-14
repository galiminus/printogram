class AddShortNameToProducts < ActiveRecord::Migration[6.0]
  def change
    add_column :products, :short_name, :string
    Product.update_all(short_name: "sticker")
  end
end
