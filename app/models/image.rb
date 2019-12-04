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

  def generate_pwinty_image!
    Pwinty.format_image(self) do |image_path|
      self.document.attach(io: open(image_path), filename: "sticker-#{self.telegram_reference}.webp")
    end
  end
end
