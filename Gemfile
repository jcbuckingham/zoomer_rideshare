source "https://rubygems.org"

ruby "3.3.0"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.3"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use Redis for Sidekiq storage and as a cache
gem "redis", "~> 5.1.0"
gem 'redis-store', "~> 1.10.0"
gem 'redis-rails', "~> 5.0.2"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

gem "rest-client", "~> 2.1.0"

# Use Sidekiq as the ActiveJob adapter
gem "sidekiq", "~> 7.2.2"

# Build JSON APIs with ease [https://github.com/rails/jbuilder]
# gem "jbuilder"

# gem "redis", ">= 4.0.1"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin Ajax possible
# gem "rack-cors"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]
  gem 'dotenv'
end

group :test do
  # Use rspec as the testing library
  gem "rspec-rails", "~> 6.1.2"
  gem "webmock", "~> 3.23.0"
  gem "awesome_print"
end
