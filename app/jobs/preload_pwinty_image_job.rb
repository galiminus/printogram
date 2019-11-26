class PreloadPwintyImageJob < ApplicationJob
  queue_as :default

  def perform(image)
    image.preload_pwinty_variant!
  end
end
