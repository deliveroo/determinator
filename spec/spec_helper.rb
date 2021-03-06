$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
Dir["./spec/support/**/*.rb"].each {|f| require f}
require 'determinator'
require 'factory_bot'
require 'rspec/its'

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

FactoryBot.define do
  initialize_with { new(attributes) }
  skip_create
end

FactoryBot.find_definitions
