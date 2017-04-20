require_relative 'boot'

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_view/railtie"

# DETERMINATOR: We must explicitly require the routemaster backend we want to use
require "routemaster/jobs/backends/sidekiq"

Bundler.require(*Rails.groups)

module DeterminatorExample
  class Application < Rails::Application
    config.api_only = true
  end
end
