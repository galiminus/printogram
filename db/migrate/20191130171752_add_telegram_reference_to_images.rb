class AddTelegramReferenceToImages < ActiveRecord::Migration[6.0]
  def change
    add_column :images, :telegram_reference, :string
  end
end
