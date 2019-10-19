class AddProductToImages < ActiveRecord::Migration[6.0]
  def change
    add_belongs_to :images, :product
  end
end
