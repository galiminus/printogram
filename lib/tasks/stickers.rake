namespace :stickers do
  task :test do
    output_dir = Rails.root.join("tmp/stickers")
    FileUtils.rm_r output_dir
    FileUtils.mkdir_p output_dir

    Dir[Rails.root.join("test/stickers/samples").to_s + "/*.webp"].each do |sample|
      puts "Generate final image for: #{sample}"
      system("convert #{sample} #{output_dir.join(File.basename(sample, '.webp') + ".png").to_s.shellescape}")

      Pwinty.format_image(sample) do |output_path|
        system("convert #{output_path.to_s.shellescape} -alpha off #{output_dir.join(File.basename(sample, '.webp') + "_final.png").to_s.shellescape}")
      end
    end
    puts "Output directory: #{output_dir}"
  end
end