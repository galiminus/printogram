class RemoveTelegramId < ActiveRecord::Migration[6.0]
  def change
    remove_column :customers, :telegram_id_ciphertext, :string
  end
end
