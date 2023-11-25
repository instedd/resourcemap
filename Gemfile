source 'https://rubygems.org'

# framework
gem 'rails', '~> 5.0.0'

# services
gem "elasticsearch", '~> 1.0.17'
gem 'mysql2', '~> 0.3.17'
gem 'puma', '~> 3.11.4'
gem 'redis', '~> 3.1'
gem "resque", '~> 1.25', :require => "resque/server"
gem 'resque-scheduler', '~> 3.0.0'

# exernal services
gem 'google-api-client', '~> 0.10'
gem 'instedd_telemetry', git: "https://github.com/instedd/telemetry_rails", branch: 'master'
gem 'intercom-rails'
gem "nuntium_api", "~> 0.13", :require => "nuntium"

# authentication/authorization
gem 'devise', '~> 4.0'
gem 'cancancan', '~> 1.9'
gem "omniauth", '~> 1.2'
gem "omniauth-openid", '~> 1.0'
gem 'alto_guisso', :git => "https://github.com/instedd/alto_guisso", branch: 'master'
gem 'alto_guisso_rails', :git => "https://github.com/instedd/alto_guisso_rails", branch: 'master'

# libraries
gem 'actionpack-action_caching'
gem 'actionpack-page_caching'
gem 'active_model_serializers'        # TODO: consider removing (one serializer)
gem 'activerecord-import'
gem "breadcrumbs_on_rails"
gem 'carrierwave'
gem 'decent_exposure'                 # NOTE: pattern used in 12 out of 29 controllers (useful?)
gem 'gettext', '~> 3.1.2'
gem 'gettext_i18n_rails_js', git: "https://github.com/juanboca/gettext_i18n_rails_js.git", branch: 'master'
gem 'ice_cube'
# gem 'includes-count'                  # TODO: remove (only one use + breaking ActiveRecord with a frozen array)
gem "instedd-rails" #, '~> 0.0.24'
gem 'mini_magick'
gem 'msgpack', '~> 0.7.5'
gem 'nokogiri'
gem 'oj', '~> 2.15.0'
gem 'paranoia', '~> 2.0'              # NOTE: consider removing (only one use)
# gem 'ruby_parser', :require => false, :group => :development
gem 'rubyzip', '1.3.0' # last version to support ruby 2.3
gem 'treetop', '1.4.15'
gem 'uuidtools'
gem 'will_paginate'

# deprecated (to fix upgrades)
gem "loofah", "2.20.0" if RUBY_VERSION.to_f < 2.5

# templates
gem 'haml-rails', '~> 0.4'
gem 'haml-magic-translations'

# assets
gem 'coffee-rails', '~> 4.1.1'
gem 'jquery-rails', "~> 4.1.0"
gem 'lodash-rails'
gem 'knockoutjs-rails', '~> 3.5.0'
gem 'rails-assets-knockout-sortable', :source => 'https://rails-assets.org'
gem 'sass-rails',   '~> 5.0'
gem 'uglifier', '>= 2.5.0'

# dependency fixes (to be removed)
gem 'dalli', '~> 2.7' # alto_guisso_rails dependency, dalli >= 3.0 require Ruby 2.5+
# gem "thor", "~> 0.20" # 0.19.4 prints warnings (e.g. expected string default value for --serializer)

group :development do
  # gem 'ruby-prof' '< 1.0.0'
  # gem 'web-console', '~> 2.0'
end

group :test do
  gem 'capybara', '~> 2.18'       # 3.x requires rack 1.6 but rails 4.1 requires 1.5
  gem 'database_cleaner'
  gem 'faker'
  gem 'machinist', '1.0.6'
  gem 'resque_spec'
  gem 'selenium-webdriver', '3.141.0' # locked until we upgrade to capybara 3.x
  gem 'shoulda-matchers', require: false
  gem 'simplecov', require: false
  gem 'spring-commands-rspec'
  gem 'timecop'
end

group :test, :development do
  # gem 'quiet_assets', '~> 1.1.0'
  # gem 'guard-jasmine', '~> 2.0.6'
  gem 'jasmine', '~> 2.7.0'
  # gem 'memory_profiler'
  # gem 'pry-byebug'
  gem 'rspec-rails', '~> 3.5.0'
  gem 'rspec-retry'
  # gem 'stackprof'
  gem 'byebug'
end

# group :development do
#   gem 'pry-stack_explorer'
#   gem 'dist', :git => 'https://github.com/manastech/dist.git'
#   gem 'better_errors', '<2.0.0'
#   gem 'binding_of_caller' # already provided by pry-stack_explorer
#   gem 'rails-dev-tweaks'
# end
