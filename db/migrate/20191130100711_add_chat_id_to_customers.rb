class AddChatIdToCustomers < ActiveRecord::Migration[6.0]
  def change
    add_column :customers, :chat_reference, :integer
  end
end
