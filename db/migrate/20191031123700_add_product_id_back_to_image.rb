class AddProductIdBackToImage < ActiveRecord::Migration[6.0]
  def change
    add_reference :images, :product, index: true
    # Image.update_all(product_id: Product.first.id)
  end
end
