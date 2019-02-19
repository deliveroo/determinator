require_relative 'boot'

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module DeterminatorExample
  class Application < Rails::Application
    config.api_only = true
  end
end
