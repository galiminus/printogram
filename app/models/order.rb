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

  PWINTY_SHIPPING_METHODS = %w{Budget}
  PWINTY_SHIPPING_ETA = {
    "Budget" => 2.weeks.from_now,
    "Standard" => 1.week.from_now,
  }
  PWINTY_SHIPPING_NAME_OVERRIDE = {
    "Budget" => "Standard",
    "Standard" => "Premium"
  }

  belongs_to :customer
  belongs_to :coupon, optional: true
  has_many :images, dependent: :destroy
  accepts_nested_attributes_for :images, allow_destroy: true

  has_one_attached :cart

  after_create :update_pwinty_order
  after_save :update_pwinty_order, if: -> {
    PWINTY_ATTRIBUTES.any? { |attribute| saved_change_to_attribute?(attribute) }
  }
  after_save :submit_pwinty_order, if: -> {
    previous_changes["state"] == ["draft", "closed"]
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
    prices = images.group_by(&:product).map do |product, images|
      [ product, [0, images.count - (coupon.present? && coupon.product == product ? coupon.count : 0)].max ]
    end.sum do |product, count|
      product.price * count
    end
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

  def cancel_pwinty_order
    Pwinty.update_order_status(self, { status: "Cancelled" })
  rescue => error
    ExceptionNotifier.notify_exception(error)
  end

  def submit_pwinty_order
    Pwinty.update_order_status(self, { status: "Submitted" })
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
      shipping_info = JSON.parse(Pwinty.get_order(self).body)["data"]["shippingInfo"]

      if shipping_info["price"] > 0
        normalized_shipping_info = {}

        # Convert price to USD
        normalized_shipping_info["usd_price"] = Money.new(shipping_info["price"], ENV["PWINTY_ACCOUNT_CURRENCY"] || "EUR").exchange_to("USD").cents

        # The API seems to only provide ETA from the same country, so it's probably better to use our own
        normalized_shipping_info["estimated_arrival_date"] = PWINTY_SHIPPING_ETA[shipping_method] || DateTime.parse(details["shipments"].first["latestEstimatedArrivalDate"])

        # Rename the shipping option, budget is too cheap
        normalized_shipping_info["shipping_method"] = PWINTY_SHIPPING_NAME_OVERRIDE[shipping_method] || shipping_method

        # Rename the carrier
        normalized_shipping_info["carrier"] =
          if shipping_info["shipments"].first["carrier"].blank?
            "UK Postal Service"
          elsif shipping_info["shipments"].first["carrier"].match(/UK .* Postal Service/i)
            "UK Postal Service"
          else
            shipping_info["shipments"].first["carrier"]
          end

        [shipping_method, normalized_shipping_info]
      else
        nil
      end
    end.compact.to_h
  end
end
