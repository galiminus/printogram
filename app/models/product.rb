class Product < ApplicationRecord
  def formated_price
    Money.new(self.price, "USD").format(symbol: '$')
  end
end
