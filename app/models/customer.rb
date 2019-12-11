class Customer < ApplicationRecord
  encrypts :name, type: :string
  encrypts :username, type: :string

  has_many :orders

  def draft_order
    self.orders.find_or_create_by(state: 'draft')
  end

  def ongoing_order
    self.orders.order(created_at: :desc).find_by(state: "ongoing")
  end

  def self.create_from_telegram!(from)
    self.find_or_create_by!(telegram_reference: from["id"]) do |user|
      user.name = from["first_name"]
      user.username = from["username"]
    end
  end

  def generate_data!
    Tempfile.create([telegram_reference, ".json"]) do |f|
      f.write(JSON.pretty_generate(self.as_json))
      f.flush
      yield f.path
    end
  end

  def as_json(options = {})
    {
      created_at: self.created_at,
      telegram_id: self.telegram_reference,
      name: self.name,
      username: self.username,
      orders: self.orders.where.not(state: 'draft').as_json
    }
  end
end
