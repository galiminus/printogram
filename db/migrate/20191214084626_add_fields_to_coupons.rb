class AddFieldsToCoupons < ActiveRecord::Migration[6.0]
  def change
    add_column :coupons, :end_at, :datetime
    add_column :coupons, :ratio, :float
    add_column :coupons, :use_limit, :integer, default: 1
    add_column :coupons, :use_limit_by_customer, :integer, default: 1
  end
end
