# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'determinator/version'

Gem::Specification.new do |spec|
  spec.name          = "determinator"
  spec.version       = Determinator::VERSION
  spec.authors       = ["JP Hastings-Spital"]
  spec.email         = ["jp@deliveroo.co.uk"]

  spec.summary       = %q{Determine which experiments and features a specific actor should see.}
  spec.homepage      = "https://github.com/deliveroo/determinator"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "faraday"
  spec.add_runtime_dependency "semantic", "~> 1.6"

  spec.add_development_dependency "bundler", "~> 2.1.4"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-its", "~> 1.2"
  spec.add_development_dependency "guard-rspec", "~> 4.7"
  spec.add_development_dependency "factory_girl", "~> 4.8"
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency "sidekiq"
end
