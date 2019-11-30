class Image < ApplicationRecord
  belongs_to :order
  belongs_to :product

  has_one_attached :document

  def download!
    save_to_cache do |local_path|
      unless File.exists?(local_path)
        sticker_file_path = Telegram.bots[:order].get_file(file_id: self.telegram_reference)["result"]["file_path"]
        sticker_url = "https://api.telegram.org/file/bot#{Telegram.bots[:order].token}/#{sticker_file_path}"

        system("curl -s #{sticker_url.shellescape} --output #{local_path}")
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

    document.variant({
      trim: true,
      resize_and_pad: [512, (512 * (1 / product.scale)).floor, { gravity: 'center' }],
      background: 'none',
      extent: 532,
      convert: :png,
      repage: "+0+0"
    })
  end
end
