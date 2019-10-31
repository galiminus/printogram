class AddPwintyReferenceToImages < ActiveRecord::Migration[6.0]
  def change
    add_column :images, :pwinty_reference, :integer, index: true
  end
end
