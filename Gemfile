source "https://rubygems.org"

ruby "3.3.6"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.0"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Redis adapter to run Action Cable in production
gem "redis", ">= 4.0.1"

# Use Kaminari for pagination
gem "kaminari"

# Use Ransack for advanced search functionality
gem "ransack"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"
gem "devise", "~> 4.9.4"
gem 'omniauth-rails_csrf_protection', '~> 1.0'
gem 'omniauth-saml', '~> 2.1'

gem "dartsass-rails"
gem "bootstrap", "~> 5.3.3"

gem "ldap_lookup" # will use for admin interface, add rovers
gem "pundit"
# export to pdf
gem 'prawn', '~> 2.5'
gem "prawn-table", "~> 0.2.2"
gem 'acts_as_list', '~> 1.2', '>= 1.2.4'
gem "skylight"
gem 'sentry-ruby'
gem 'sentry-rails'
gem 'country_select'

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]
  gem 'rspec-rails', '~> 8.0.0'
  gem 'factory_bot_rails'
  gem 'capybara', '~> 3.40'
  gem 'webdrivers', '= 5.3.0'
  gem 'faker'
  gem 'pry'
  gem 'pundit-matchers', '~> 3.1', '>= 3.1.2'
  gem 'brakeman', require: false
  gem 'rails_accessibility_testing', '~> 1.5', '>= 1.5.10'
  gem 'axe-core-capybara', '~> 4.0'
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem 'annotaterb', '~> 4.13'
end

group :development, :staging do
  gem "letter_opener_web"
end
