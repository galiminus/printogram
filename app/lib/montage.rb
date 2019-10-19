class Montage
  def self.create_cart(order)
    Dir.mktmpdir do |wdir|
      # image_paths = []
      # order.images.map(&:document).map.with_index do |image, index|
      #   image.open do |instance|
      #     image_paths << "#{wdir}/#{index}.webp".tap do |destination|
      #       FileUtils.copy instance.path, destination
      #     end
      #   end
      # end

      image_paths = order.images.map(&:document).map do |document|
        document.blob.service_url
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