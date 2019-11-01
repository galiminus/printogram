module Pwinty
  def self.client
    @client ||= RestClient::Resource.new(
      Rails.application.credentials.pwinty[:api_url],
      headers: {
        "X-Pwinty-MerchantId" =>  Rails.application.credentials.pwinty[:merchant_id],
        "X-Pwinty-REST-API-Key" =>  Rails.application.credentials.pwinty[:api_key],
      }
    )
  end

  def self.create_order(params)
    client["orders"].post(params)
  end

  def self.get_order(order)
    client["orders"][order.pwinty_reference].get
  end

  def self.validate_order(order)
    client["orders"][order.pwinty_reference]["SubmissionStatus"].get
  end

  def self.create_image(order, params)
    client["orders"][order.pwinty_reference]["images"].post(params)
  end

  def self.check_order_validity(order)
    client["orders"][order.pwinty_reference]["SubmissionStatus"].get
  end

  def self.submit_order(order)
    client["orders"][order.pwinty_reference]["status"].post(state: :submitted)
  end

  def self.countries
    parse_response client["countries"].get
  end

  def self.prices(country_code:, skus:)
    parse_response client["catalogue"]["prodigi%20direct"]["destination"][country_code]["prices"].post({ skus: skus })
  end

  def self.parse_response(response)
    JSON.parse response.body
  end
end