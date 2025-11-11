# frozen_string_literal: true

require_relative "version"

Gem::Specification.new do |spec|
  spec.name          = "rails_accessibility_testing"
  spec.version       = RailsAccessibilityTesting::VERSION
  spec.authors       = ["Regan Maharjan"]
  spec.email         = ["imregan@umich.edu"]

  spec.summary       = "Zero-configuration accessibility testing for Rails system specs"
  spec.description   = "Automatically configures axe-core-capybara and provides helpers for accessibility testing"
  spec.homepage      = "https://github.com/rayraycodes/rails_accessibility_testing"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.add_dependency "axe-core-capybara", "~> 4.0"
  spec.add_dependency "capybara", "~> 3.0"
  spec.add_dependency "rspec-rails", "~> 6.0"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
end

