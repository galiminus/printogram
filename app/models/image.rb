class Image < ApplicationRecord
  belongs_to :order
  belongs_to :product

  has_one_attached :document

  def create_pwinty_image!
    ActiveStorage.variable_content_types = (ActiveStorage.variable_content_types + ["image/webp"]).uniq # pretty dirty, but well...

    response = Pwinty.create_image(order, {
      sku: product.sku,
      url: document.variant(convert: :png).processed.service_url,
      copies: 1,
      sizing: "ShrinkToFit",
    })
    self.update(pwinty_reference: JSON.parse(response.body)["data"]["id"])
  end

  def download!
    save_to_cache do |local_path|
      unless File.exists?(local_path)
        byebug
        system("curl -s #{document.service_url.shellescape} --output #{local_path}")
      end
    end
  end

  def local_path
    "#{ENV["IMAGE_DOCUMENT_CACHE"] || "/tmp"}/#{Digest::SHA1.hexdigest(id.to_s).insert(3, '/')}.webp"
  end

  def save_to_cache
    FileUtils.mkdir_p File.dirname(local_path)
    yield local_path

    local_path
  end
end
