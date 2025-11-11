# frozen_string_literal: true

# Rails Accessibility Testing Gem
# Automatically configures accessibility testing for Rails system specs
#
# @example Basic usage
#   # In spec/rails_helper.rb
#   require 'rails_accessibility_testing'
#
#   # That's it! Checks run automatically on system specs
#
# @example Custom configuration
#   RailsAccessibilityTesting.configure do |config|
#     config.use_basic_checks  # Only run basic checks
#     config.change_window_seconds = 600  # 10 minutes
#   end

require 'axe-capybara'
require 'axe/matchers/be_axe_clean'

# Load version
begin
  require_relative 'rails_accessibility_testing/version'
rescue LoadError
  module RailsAccessibilityTesting
    VERSION = '1.0.0'
  end
end

# Load core components
require_relative 'rails_accessibility_testing/configuration'
require_relative 'rails_accessibility_testing/change_detector'
require_relative 'rails_accessibility_testing/error_message_builder'
require_relative 'rails_accessibility_testing/accessibility_helper'
require_relative 'rails_accessibility_testing/shared_examples'
require_relative 'rails_accessibility_testing/rspec_integration'

# Auto-configure when RSpec is available
if defined?(RSpec)
  RSpec.configure do |config|
    RailsAccessibilityTesting::RSpecIntegration.configure!(config)
  end
end
