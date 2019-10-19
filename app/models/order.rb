class Order < ApplicationRecord
  belongs_to :customer
  has_many :images

  has_one_attached :cart

  def reference
    Zlib::crc32("#{id}#{customer.telegram_id}")
  end

  def price
    images.map { |image| image.product.price }.sum
  end

  def formatted_price
    Money.new(self.price, "USD").format(symbol: '$')
  end
end
