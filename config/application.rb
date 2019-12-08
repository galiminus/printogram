require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Printogram
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.site_name = ENV["SITE_NAME"] ||  Rails.application.class.module_parent_name
    config.max_image_count_per_order = (ENV["MAX_IMAGE_COUNT_PER_ORDER"] || 100).to_i
  end
end
