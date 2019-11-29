class RemoveDefaultToCountryCode < ActiveRecord::Migration[6.0]
  def change
    change_column :orders, :country_code, :string, default: nil
  end
end
