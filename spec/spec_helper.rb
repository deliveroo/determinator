$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require 'determinator'
require 'factory_girl'

RSpec.configure do |config|
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
end

FactoryGirl.define do
  initialize_with { new(attributes) }
  skip_create
end

FactoryGirl.find_definitions

