class Montage
  def self.create_cart(order)
    Dir.mktmpdir do |wdir|
      image_paths = []
      order.images.map(&:document).map.with_index do |image, index|
        image.open do |instance|
          image_paths << "#{wdir}/#{index}.webp".tap do |destination|
            FileUtils.copy instance.path, destination
          end
        end
      end

      image_params = image_paths.map.with_index do |image_path, index|
        "-label #{index + 1} #{image_path.shellescape}"
      end.join(" ")
      output = "#{wdir}/output.png"

      system("montage #{image_params} #{output}")

      yield output
    end
  end
end