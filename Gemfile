source 'https://rubygems.org'

gem 'rails', '3.2.11'
gem 'mysql2'
gem 'devise'
gem 'haml-rails'
gem 'decent_exposure'
gem "instedd-rails", '0.0.17'
gem "breadcrumbs_on_rails"
gem "tire"
gem "valium"
gem "resque", :require => "resque/server"
gem 'resque-scheduler', :require => 'resque_scheduler'
gem "nuntium_api", "~> 0.13", :require => "nuntium"
gem 'ice_cube'
gem 'knockoutjs-rails'
gem 'will_paginate'
gem 'jquery-rails', "~> 2.0.2"
gem 'foreman'
gem 'uuidtools'
gem 'cancan'

group :test do
  gem 'shoulda-matchers'
  gem 'ci_reporter'
  gem 'resque_spec'
  gem 'selenium-webdriver'
  gem 'nokogiri'
  gem 'capybara'
  gem 'database_cleaner'
end

group :test, :development do
  gem 'rspec'
  gem 'rspec-rails'
  gem 'faker'
  gem 'machinist', '1.0.6'
  gem 'capistrano'
  gem 'rvm'
  gem 'rvm-capistrano', '1.2.2'
  gem 'jasminerice'
  gem 'guard-jasmine'
  gem 'pry'
  gem 'pry-debugger'
end

group :development do
  gem 'dist', :git => 'git://github.com/manastech/dist.git'
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  gem 'therubyracer'

  gem 'uglifier', '>= 1.0.3'
  gem 'lodash-rails'
end

