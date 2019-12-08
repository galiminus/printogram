class Montage
  def self.create_cart(order, full_quality: false)
    Dir.mktmpdir do |wdir|
      image_params = order.images.order(created_at: :asc).map(&:preview!).map.with_index do |image_path, index|
        "-label #{index + 1} #{image_path.shellescape}"
      end.join(" ")
      output = "#{wdir}/output.jpeg"

      dimension =
        if full_quality
          512
        else
          [256 / Math.sqrt(order.images.count).floor * 2, 128].max
        end

      pointsize = dimension / 8
      system("montage -quality 85 -font #{Rails.root}/app/assets/fonts/CarterOne-Regular.ttf -pointsize #{pointsize} -geometry #{dimension}x#{dimension}\\>+6+12 -bordercolor white -border 10 #{image_params} #{output}")

      yield output
    end
  end
end