source 'https://rubygems.org'

gem 'rails', '~> 4.1.6'
gem 'mysql2'
gem 'devise'
gem 'haml-rails', '~> 0.4'
gem 'gettext', '~> 3.1.2'
gem 'gettext_i18n_rails_js', git: "https://github.com/juanboca/gettext_i18n_rails_js.git", branch: 'master'
gem 'ruby_parser', :require => false, :group => :development
gem 'haml-magic-translations'
gem 'decent_exposure'
gem "instedd-rails", '~> 0.0.24'
gem "breadcrumbs_on_rails"
gem "elasticsearch"
gem "elasticsearch-ruby"
gem "resque", :require => "resque/server"
gem 'resque-scheduler', '~> 3.0.0'
gem "nuntium_api", "~> 0.13", :require => "nuntium"
gem 'ice_cube'
gem 'knockoutjs-rails'
gem 'will_paginate'
gem 'jquery-rails', "~> 2.0.2"
gem 'foreman'
gem 'uuidtools'
gem 'newrelic_rpm'
gem 'cancancan', '~> 1.9'
gem "omniauth"
gem "omniauth-openid"
gem 'alto_guisso', git: "https://github.com/instedd/alto_guisso.git", branch: 'master'
gem 'oj'
gem 'nokogiri'
gem 'carrierwave'
gem 'mini_magick'
gem 'activerecord-import'
gem 'active_model_serializers'
gem 'includes-count'
gem 'poirot_rails', git: "https://github.com/instedd/poirot_rails.git", branch: 'master' unless ENV['CI']

gem 'treetop', '1.4.15'

gem 'protected_attributes'
gem 'rails-observers'
gem 'actionpack-page_caching'
gem 'actionpack-action_caching'
gem 'activerecord-deprecated_finders'

gem 'msgpack'
gem 'redis'

group :test do
  gem 'shoulda-matchers', require: false
  gem 'resque_spec'
  gem 'selenium-webdriver'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'simplecov'
  gem 'simplecov-rcov'
  gem 'timecop'
end

group :test, :development do
  gem 'rspec'
  gem 'rspec-rails', '~> 3.1.0'
  gem 'spring-commands-rspec'
  gem 'faker'
  gem 'machinist', '1.0.6'
  gem 'capistrano'
  gem 'rvm'
  gem 'rvm-capistrano', '1.5.4', require: false
  gem 'jasminerice', '~> 0.1.0', :git => 'https://github.com/bradphelan/jasminerice'
  gem 'guard-jasmine'
  gem 'pry-byebug'
end

group :development do
  gem 'pry-stack_explorer'
  gem 'dist', :git => 'https://github.com/manastech/dist.git'
  gem 'ruby-prof', :git => 'https://github.com/ruby-prof/ruby-prof.git'
  gem 'better_errors', '<2.0.0'
  gem 'binding_of_caller' # already provided by pry-stack_explorer
end

# Gems used only for assets and not required
# in production environments by default.
gem 'sass-rails',   '~> 4.0.1'
gem 'coffee-rails', '~> 4.0.1'

gem 'uglifier', '>= 2.5.0'
gem 'lodash-rails'
