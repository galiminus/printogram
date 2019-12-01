class Order < ApplicationRecord
  has_paper_trail

  belongs_to :customer
  belongs_to :coupon, optional: true
  has_many :images, dependent: :destroy
  accepts_nested_attributes_for :images, allow_destroy: true


  encrypts :country_code_ciphertext, type: :string, migrating: true
  encrypts :address1_ciphertext, type: :string, migrating: true
  encrypts :address2_ciphertext, type: :string, migrating: true
  encrypts :address_town_or_city_ciphertext, type: :string, migrating: true
  encrypts :state_or_county_ciphertext, type: :string, migrating: true
  encrypts :postal_or_zip_code_ciphertext, type: :string, migrating: true
  encrypts :customer_name_ciphertext, type: :string, migrating: true


  def reference
    "#{customer.telegram_reference}-#{id}"
  end

  def token
    Base64.strict_encode64(Encryptor.encrypt(id))
  end

  def self.find_by_token(token)
    Order.find(Encryptor.decrypt(Base64.strict_decode64(token)))
  end

  def price
    prices = images.group_by(&:product).map do |product, images|
      [ product, [0, images.count - (coupon.present? && coupon.product == product ? coupon.count : 0)].max ]
    end.sum do |product, count|
      product.price * count
    end
  end

  def shipping_options
    [
      {
        "shipping_method" => "Standard",
        "usd_price" => 289,
        "estimated_arrival_date" => 10.days.from_now,
        "carrier" => "UK Postal Service",
        "pwinty_shipping_method" => "Budget"
      }
    ]
  end
end
