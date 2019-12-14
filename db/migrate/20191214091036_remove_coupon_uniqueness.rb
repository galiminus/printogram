class RemoveCouponUniqueness < ActiveRecord::Migration[6.0]
  def change
    remove_index :orders, :coupon_id
    add_index :orders, :coupon_id
  end
end
