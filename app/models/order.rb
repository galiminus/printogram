class Order < ApplicationRecord
  has_paper_trail

  belongs_to :customer
  belongs_to :coupon, optional: true
  has_many :images
  accepts_nested_attributes_for :images, allow_destroy: true

  has_one_attached :cart

  after_save :create_pwinty_order!, if: -> {
    previous_changes["state"] == ["draft", "validated"]
  }

  after_save :submit_pwinty_order!, if: -> {
    previous_changes["state"] == ["validated", "submitted"]
  }

  after_destroy :cancel_pwinty_order!, if: -> {
    pwinty_reference.present?
  }

  def reference
    "#{customer.telegram_id}-#{id}"
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

  def create_pwinty_order!
    response = Pwinty.create_order({
      merchantOrderId: self.id,
      recipientName: self.customer_name,
      countryCode: self.country_code,
      preferredShippingMethod: self.preferred_shipping_method,
      address1: self.address1,
      address2: self.address2,
      addressTownOrCity: self.address_town_or_city,
      stateOrCounty: self.state_or_county,
      postalOrZipCode: self.postal_or_zip_code
    })
    self.update(pwinty_reference: JSON.parse(response.body)["data"]["id"])

    images.each do |image|
      Pwinty.create_images(self, {
        sku: image.product.sku,
        url: image.pwinty_variant.processed.service_url,
        copies: 1,
        sizing: "Crop",
      })
    end
  end

  def cancel_pwinty_order!
    Pwinty.update_order_status(self, { status: "Cancelled" })
  rescue => error
    ExceptionNotifier.notify_exception(error)
  end

  def submit_pwinty_order!
    Pwinty.update_order_status(self, { status: "Submitted" })
  end

  def shipping_options
    [
      {
        "shipping_method" => "Standard",
        "usd_price" => 289,
        "estimated_arrival_date" => 10.days.from_now,
        "carrier" => "UK Postal Service"
      }
    ]
  end
end
