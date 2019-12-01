class Customer < ApplicationRecord
  encrypts :telegram_id, migrating: true, type: :integer
  encrypts :name, migrating: true, type: :string
  encrypts :username, migrating: true, type: :string

  has_many :orders

  def draft_order
    self.orders.find_or_create_by(state: 'draft')
  end

  def ongoing_order
    self.orders.order(created_at: :desc).find_by(state: "ongoing")
  end

  def self.create_from_telegram!(from)
    self.find_or_create_by!(telegram_id: from["id"]) do |user|
      user.name = from["first_name"]
      user.username = from["username"]
    end
  end
end
