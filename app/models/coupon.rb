class Coupon < ApplicationRecord
  include ActionView::Helpers::TextHelper

  CODE_CHARACTER_SET = ('A'..'Z').to_a - ['O', 'I'] + ('1'..'9').to_a
  CODE_LENGTH = 6

  has_many :orders
  belongs_to :product

  validates :count, presence: true

  before_create :set_code

  def set_code
    self.code = (0...CODE_LENGTH).map { CODE_CHARACTER_SET[SecureRandom.random_number(CODE_CHARACTER_SET.size)] }.join
  end

  def name
    "#{code} - #{count} stickers"
  end

  def as_words
    pluralize(count, "free #{product.name}")
  end
end
