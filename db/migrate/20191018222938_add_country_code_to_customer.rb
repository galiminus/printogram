class AddCountryCodeToCustomer < ActiveRecord::Migration[6.0]
  def change
    add_column :customers, :country_code, :string
  end
end
