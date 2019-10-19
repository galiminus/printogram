class Order < ApplicationRecord
  belongs_to :customer
  has_many :images, dependent: :destroy

  has_one_attached :cart

  def reference
    Zlib::crc32("#{id}#{customer.telegram_id}")
  end

  def token
   Base64.strict_encode64("#{id}:#{Digest::SHA1.digest(id.to_s)[0..8]}")
  end

  def self.find_by_token(token)
    Order.find(Base64.strict_decode64(token).split(":")[0]).tap do |record|
      raise ActiveRecord::RecordNotFound if record.token != token
    end
  end

  def price
    images.map { |image| image.product.price }.sum
  end

  def formatted_price
    Money.new(self.price, "USD").format(symbol: '$')
  end

  def update_address!(components)
    def find_component(components, type)
      components.find do |component|
        component["types"].include? type
      end
    end

    street_number = components.find { |c| c["types"].include?("street_number") }
    route = components.find { |c| c["types"].include?("route") }
    city = components.find { |c| c["types"].include?("locality") }
    level_1 = components.find { |c| c["types"].include?("administrative_area_level_1") }
    country = components.find { |c| c["types"].include?("country") }
    postal_code = components.find { |c| c["types"].include?("postal_code") }

    address1 = if route.try(:[], "long_name").present?
      [street_number.try(:[], "long_name"), route.try(:[], "long_name")].join(", ")
    else
      nil
    end

    update!({
      address1: address1,
      address_town_or_city: city.try(:[], "long_name"),
      state_or_county: level_1.try(:[], "long_name"),
      postal_or_zip_code: postal_code.try(:[], "long_name"),
      country_code: country.try(:[], "long_name")
    })
  end

  def clear_address
    update!({
      address1: nil,
      address_town_or_city: nil,
      state_or_county: nil,
      postal_or_zip_code: nil,
      country_code: nil
    })
  end
end