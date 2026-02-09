# Bullet configuration for N+1 query detection
if defined?(Bullet)
  Bullet.enable        = true
  Bullet.alert         = true
  # Bullet.alert = false # Disable browser alerts (can be annoying)
  Bullet.console = true # Print in server console
  Bullet.rails_logger = true # Add to Rails.logger
  Bullet.bullet_logger = true # Log to bullet.log file
  Bullet.add_footer = true # Add footer with detected issues
  
  # Disable specific checks if needed
  # Bullet.unused_eager_loading_enable = false
  # Bullet.counter_cache_enable = false
  
  # Only show N+1 queries (most important)
  Bullet.n_plus_one_query_enable = true
  Bullet.unused_eager_loading_enable = true
  Bullet.counter_cache_enable = true
end
