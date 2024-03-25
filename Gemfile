source "https://rubygems.org"

ruby "3.3.0"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.3"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use Redis for caching
gem "redis", "~> 5.1.0"
gem 'redis-store', "~> 1.10.0"
gem 'redis-rails', "~> 5.0.2"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Use HTTPart for requests
gem "httparty"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ]
  gem 'dotenv'
end

group :test do
  # Use rspec as the testing library
  gem "rspec-rails", "~> 6.1.2"
  gem "webmock", "~> 3.23.0"
end

