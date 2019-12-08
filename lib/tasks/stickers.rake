namespace :stickers do
  task :test do
    output_dir = Rails.root.join("tmp/stickers")
    FileUtils.rm_r output_dir
    FileUtils.mkdir_p output_dir

    Dir[Rails.root.join("test/stickers/samples").to_s + "/*.webp"].each do |sample|
      system("convert #{sample} #{output_dir.join(File.basename(sample, '.webp') + ".png").to_s.shellescape}")

      puts "Generate final image for: #{sample}"
      Pwinty.format_image(sample) do |output_path|
        system("convert #{output_path.to_s.shellescape} -alpha off #{output_dir.join(File.basename(sample, '.webp') + "_final.png").to_s.shellescape}")
      end

      puts "Generate preview image for: #{sample}"
      Pwinty.format_preview(sample) do |output_path|
        system("convert #{output_path.to_s.shellescape} #{output_dir.join(File.basename(sample, '.webp') + "_preview.png").to_s.shellescape}")
      end
    end
    puts "Output directory: #{output_dir}"
  end
end