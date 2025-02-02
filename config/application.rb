# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Pick the frameworks you want:
require 'active_model/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'view_component/engine'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module FindTeacherTraining
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.exceptions_app = routes

    # https://thoughtbot.com/blog/content-compression-with-rack-deflater
    config.middleware.use Rack::Deflater

    config.skylight.environments = Settings.skylight_enable ? [Rails.env] : []
  end
end
