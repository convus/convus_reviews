require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module ConvusReviews
  class Application < Rails::Application
    config.redis_default_url = ENV["REDIS_URL"]
    config.redis_cache_url = ENV["REDIS_CACHE_URL"]

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "America/Los_Angeles"

    # config.eager_load_paths << Rails.root.join("extras")

    config.active_record.belongs_to_required_by_default = false

    # Don't generate system test files.
    config.generators.system_tests = nil

    $prefab = Prefab::Client.new
    $prefab.set_rails_loggers
  end
end
