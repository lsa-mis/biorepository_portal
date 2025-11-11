# frozen_string_literal: true

module RailsAccessibilityTesting
  # Configuration for the accessibility testing gem
  class Configuration
    attr_accessor :auto_run_checks

    def initialize
      @auto_run_checks = true
    end
  end

  # Global configuration instance
  def self.config
    @config ||= Configuration.new
  end

  # Configure the gem
  def self.configure
    yield config if block_given?
  end
end

