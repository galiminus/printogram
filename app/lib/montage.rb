class Montage
  def self.create_cart(order)
    Dir.mktmpdir do |wdir|
      image_paths = order.images.map(&:document).map(&:service_url).map.with_index do |url, index|
        "#{wdir}/#{index}.webp".tap do |output|
          system("curl -s #{url.shellescape} --output #{output}")
        end
      end

      image_params = image_paths.map.with_index do |image_path, index|
        "-label #{index + 1} #{image_path.shellescape}"
      end.join(" ")
      output = "#{wdir}/output.webp"

      system("montage -pointsize 32 -geometry +2+2 #{image_params} #{output}")

      yield output
    end
  end
end