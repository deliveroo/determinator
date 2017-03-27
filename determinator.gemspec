# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'determinator/version'

Gem::Specification.new do |spec|
  spec.name     = 'determinator'
  spec.version  = Determinator::VERSION
  spec.authors  = ['JP Hastings-Spital']
  spec.email    = ['jp@deliveroo.co.uk']

  spec.summary  = %q{Determine which experiments and features a specific actor should see.}
  spec.homepage = 'https://github.com/deliveroo/determinator'
  spec.license  = 'MIT'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    abort 'RubyGems 2.0 or newer is required to protect against public gem pushes.'
  end

  spec.files = Dir['*.md', 'lib/**/*']
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'guard-rspec', '~> 4.7'
  spec.add_development_dependency 'factory_girl', '~> 4.8'
end
