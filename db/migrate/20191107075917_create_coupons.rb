class CreateCoupons < ActiveRecord::Migration[6.0]
  def change
    create_table :coupons do |t|
      t.string :code
      t.integer :count
      t.belongs_to :product
      t.timestamps
    end
    add_reference :orders, :coupon, index: { unique: true }
  end
end
