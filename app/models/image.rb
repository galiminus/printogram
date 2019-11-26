class Image < ApplicationRecord
  belongs_to :order
  belongs_to :product

  has_one_attached :document

  def download!
    save_to_cache do |local_path|
      unless File.exists?(local_path)
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

  def pwinty_variant
    ActiveStorage.variable_content_types = (ActiveStorage.variable_content_types + ["image/webp"]).uniq # pretty dirty, but well...

    document.variant(resize_and_pad: [512, (512 * (1 / product.scale)).floor], convert: :png)
  end

  def preload_pwinty_variant!
    pwinty_variant.processed
  end
end
