# Prosopite configuration for N+1 query detection
# Replaces Bullet gem — works better with Rails 8
if defined?(Prosopite)
  Prosopite.rails_logger = true
  Prosopite.raise = Rails.env.test?
end
