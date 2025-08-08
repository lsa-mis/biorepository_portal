# frozen_string_literal: true

Sentry.init do |config|
  # Use credentials instead of ENV or hardcoded value
  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)

  # Only enable in production and staging environments
  config.enabled_environments = %w[production staging]

  # Logging configuration
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Add user context data (PII)
  config.send_default_pii = true

  # Performance monitoring
  # In production, you might want to lower this to something like 0.1 (10%)
  # depending on your traffic volume
  config.traces_sample_rate = Rails.env.production? ? 0.1 : 1.0

  # Profile sampling - adjust based on your needs
  config.profiles_sample_rate = Rails.env.production? ? 0.1 : 1.0

  # Custom sampling logic if needed
  config.traces_sampler = lambda do |context|
    # Don't sample health check endpoints
    if context[:transaction_context][:name]&.include?('health_check')
      0.0
    else
      # Sample based on environment
      Rails.env.production? ? 0.1 : 1.0
    end
  end

  # Add additional context to errors
  config.before_send = lambda do |event, hint|
    # You can add custom data here
    if defined?(Current) && Current.user
      event.user = {
        id: Current.user.id,
        email: Current.user.email
      }
    end
    event
  end

  # Configure backtrace cleanup
  config.backtrace_cleanup_callback = lambda do |backtrace|
    Rails.backtrace_cleaner.clean(backtrace)
  end
end
