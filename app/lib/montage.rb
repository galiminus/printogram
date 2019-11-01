class Montage
  def self.create_cart(order)
    Dir.mktmpdir do |wdir|
      image_params = order.images.map(&:download!).map.with_index do |image_path, index|
        "-label #{index + 1} #{image_path.shellescape}"
      end.join(" ")
      output = "#{wdir}/output.webp"

      system("montage -pointsize 48 -geometry +2+2 -bordercolor white -border 10 #{image_params} #{output}")

      yield output
    end
  end
end