source 'https://rubygems.org'

gem 'rails', '4.1.14.1'
gem 'pg'
gem 'sass-rails', '~> 4.0.3'
gem 'uglifier', '>= 1.3.0'
gem 'govuk_admin_template', '~> 3.4'
gem 'select2-rails', '~> 3.5.9'
gem 'google_drive', '~> 1.0'
gem 'rest-client', '~> 1.8'
gem 'factory_girl_rails', '~> 4.5'
gem 'sidekiq', '~> 4.0'

group :development do
  gem 'annotate'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'govuk-lint'
  gem 'awesome_print'
end

group :test, :development do
  gem 'rspec-rails', '~> 3.2'
  gem 'rspec-collection_matchers', '~> 1.1'
  gem 'timecop', '~> 0.5'
  gem 'capybara'
  gem 'byebug'
  gem 'pry-byebug'
end

group :test do
  gem 'simplecov', require: false
end

group :assets do
  gem 'coffee-rails'
end

group :production do
  gem 'rails_12factor', '~> 0.0'
end
