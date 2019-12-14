class Order < ApplicationRecord
  has_paper_trail

  belongs_to :customer
  belongs_to :coupon, optional: true
  has_many :images, dependent: :destroy
  accepts_nested_attributes_for :images, allow_destroy: true

  encrypts :country_code, type: :string
  encrypts :address1, type: :string
  encrypts :address2, type: :string
  encrypts :address_town_or_city, type: :string
  encrypts :state_or_county, type: :string
  encrypts :postal_or_zip_code, type: :string
  encrypts :customer_name, type: :string

  has_one_attached :preview

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
      [
        product,
        [0, images.count - (coupon.present? && coupon.count.present? && coupon.product == product ? coupon.count : 0)].max
      ]
    end.map do |product, count|
      [ product, product.price * count ]
    end.sum do |product, price|
      if coupon.present? && coupon.ratio.present? && coupon.product == product
        (price * coupon.ratio).round
      else
        price
      end
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

  def as_json(options = {})
    {
      created_at: self.created_at,
      state: self.state,
      reference: self.reference,
      images: self.images.as_json,
      country_code: self.country_code,
      address1: self.address1,
      address2: self.address2,
      address_town_or_city: self.address_town_or_city,
      state_or_county: self.state_or_county,
      postal_or_zip_code: self.postal_or_zip_code,
      customer_name: self.customer_name
    }.tap do |base|
      if preview.attached?
        base[:preview] = self.preview.service_url
      end
    end
  end
end
