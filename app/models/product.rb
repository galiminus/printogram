class Product < ApplicationRecord
  has_paper_trail

  def formated_price
    Money.new(self.price, "USD").format(symbol: '$')
  end
end
