class Order < ApplicationRecord
  has_paper_trail

  PWINTY_ATTRIBUTES = %w{
    id
    pwinty_reference_changed
    country_code
    preferred_shipping_method
    address1
    address2
    address_town_or_city
    state_or_county
    postal_or_zip_code
  }

  PWINTY_SHIPPING_METHODS = %w{Budget Standard}

  belongs_to :customer
  has_many :images, dependent: :destroy
  accepts_nested_attributes_for :images, allow_destroy: true

  has_one_attached :cart

  after_create :update_pwinty_order
  after_save :update_pwinty_order, if: -> {
    PWINTY_ATTRIBUTES.any? { |attribute| saved_change_to_attribute?(attribute) }
  }

  after_destroy :cancel_pwinty_order, if: -> {
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
    images.map { |image| image.product.price }.sum
  end

  def update_pwinty_order
    attributes = {
      merchantOrderId: self.id,
      recipientName: self.customer_name,
      countryCode: self.country_code,
      preferredShippingMethod: self.preferred_shipping_method,
      address1: self.address1,
      address2: self.address2,
      addressTownOrCity: self.address_town_or_city,
      stateOrCounty: self.state_or_county,
      postalOrZipCode: self.postal_or_zip_code
    }

    response =
      if self.pwinty_reference.present?
        Pwinty.update_order(self, attributes)
      else
        Pwinty.create_order(attributes)
      end

    self.update(pwinty_reference: JSON.parse(response.body)["data"]["id"])

    JSON.parse(response)
  end

  def sync_pwinty_order_from_attributes

  end

  def cancel_pwinty_order
    Pwinty.update_order_status(self, { status: "Cancelled" })
  end

  def shipping_options
    shipping_methods = PWINTY_SHIPPING_METHODS.sort_by { |m| m == preferred_shipping_method ? -1 : 1 }

    shipping_methods.map do |shipping_method|
      Pwinty.update_order(self, {
        merchantOrderId: self.id,
        recipientName: self.customer_name,
        countryCode: self.country_code,
        preferredShippingMethod: shipping_method,
        address1: self.address1,
        address2: self.address2,
        addressTownOrCity: self.address_town_or_city,
        stateOrCounty: self.state_or_county,
        postalOrZipCode: self.postal_or_zip_code
      })
      response = Pwinty.get_order(self)

      [shipping_method, JSON.parse(response.body)["data"]["shippingInfo"]]
    end.to_h
  end
end
