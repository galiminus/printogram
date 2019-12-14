class Coupon < ApplicationRecord
  include ActionView::Helpers::TextHelper

  CODE_CHARACTER_SET = ('A'..'Z').to_a - ['O', 'I'] + ('1'..'9').to_a
  CODE_LENGTH = 6

  has_many :orders
  belongs_to :product

  validates :count, presence: true, if: -> { ratio.blank? }
  validates :ratio, presence: true, if: -> { count.blank? }

  before_create :set_code

  def set_code
    self.code = (0...CODE_LENGTH).map { CODE_CHARACTER_SET[SecureRandom.random_number(CODE_CHARACTER_SET.size)] }.join
  end

  def name
    "#{code} - #{count} stickers"
  end

  def as_words
    reduction =
      if ratio.present?
        "#{(100 - self.ratio * 100).to_i}% off"
      else
        pluralize(count, "free #{product.short_name}")
      end

    if use_limit_by_customer.blank?
      reduction
    elsif use_limit_by_customer == 1
      "#{reduction} on your first purchase"
    else
      "#{reduction} on your first #{use_limit_by_customer} purchases"
    end
  end

  def expired?
    self.end_at.present? && self.end_at < Time.now
  end

  def is_in_use_limit?
    self.use_limit.blank? || self.orders.count < self.use_limit
  end

  def is_in_use_limit_by_customer?(customer)
    self.use_limit_by_customer.blank? || self.orders.where(customer: customer).count < self.use_limit_by_customer
  end
end
