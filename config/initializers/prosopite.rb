# Prosopite configuration for N+1 query detection
# Replaces Bullet gem — works better with Rails 8
Prosopite.rails_logger = true
Prosopite.raise = Rails.env.test?
