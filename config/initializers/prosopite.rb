# config/initializers/prosopite.rb

if defined?(Prosopite)
  Prosopite.rails_logger = true
  Prosopite.prosopite_logger = true
  Prosopite.stderr_logger = true

  # For this investigation, log N+1 warnings without breaking local pages.
  # Later the team can decide whether to make this true in test.
  Prosopite.raise = false

  # Focus stack traces on application code.
  Prosopite.allow_stack_paths = [
    Rails.root.join("app").to_s
  ]

  Prosopite.backtrace_cleaner = Rails.backtrace_cleaner if Rails.respond_to?(:backtrace_cleaner)
end