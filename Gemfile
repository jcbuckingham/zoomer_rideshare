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

# Use Devise and JWT for authentication
gem "devise", "4.9.4"
gem "devise-jwt", "0.11.0"
gem "jsonapi-serializer", "2.2.0"
gem "rack-cors", "2.0.2"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

gem "awesome_print"

group :development, :test do
  gem 'dotenv'
end

group :test do
  gem "rspec-rails", "~> 6.1.2"
  gem "webmock", "~> 3.23.0"
end

