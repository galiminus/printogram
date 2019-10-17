class Product < ApplicationRecord
  def to_keyboard
    "#{name}"
  end
end
