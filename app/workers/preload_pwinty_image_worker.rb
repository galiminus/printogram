class PreloadPwintyImageWorker
  include Sidekiq::Worker

  def perform(image_id)
    Image.find_by(id: image_id)&.preload_pwinty_variant!
  end
end
