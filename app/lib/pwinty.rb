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

  def self.update_order(order, params)
    client["orders"][order.pwinty_reference].put(params)
  end

  def self.get_order(order)
    client["orders"][order.pwinty_reference].get
  end

  def self.validate_order(order)
    client["orders"][order.pwinty_reference]["SubmissionStatus"].get
  end

  def self.update_order_status(order, params)
    client["orders"][order.pwinty_reference]["Status"].post(params)
  end

  def self.create_image(order, params)
    client["orders"][order.pwinty_reference]["images"].post(params)
  end

  def self.create_images(order, params)
    client["orders"][order.pwinty_reference]["images"]["batch"].post(params)
  end

  def self.check_order_validity(order)
    client["orders"][order.pwinty_reference]["SubmissionStatus"].get
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

  def self.format_image(image_path)
    Dir.mktmpdir do |wdir|
      output = "#{wdir}/output.png"
      convert_path = Rails.root.join("vendor/imagemagick/bin/convert")

      system("#{convert_path.exist? ? "MAGICK_CONFIGURE_PATH=#{Rails.root}/vendor/imagemagick/etc/ImageMagick-7/ #{convert_path}" : "convert"} #{image_path.shellescape} -channel A -black-threshold 0% +channel -bordercolor none -border 6 \\( -clone 0 -alpha off -fill white -colorize 100% \\) \\( -clone 0 -alpha extract -morphology edgeout octagon\
:6 \\) -compose over -composite  -trim -background none -gravity center -resize 512x682 -extent 572x762 -repage +0+0 #{output.shellescape}")
      raise if $? != 0

      yield output
    end
  end
end