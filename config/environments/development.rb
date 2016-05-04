ResourceMap::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  gem 'devise'
  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  config.eager_load = false

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.default_url_options = { :host => Settings.host }

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address              => "smtp.mandrillapp.com",
    :port                 => 587,
    :domain               => 'resourcemap.instedd.org',
    :user_name            => 'sreng@instedd.org',
    :password             => '83adfb21-add5-4728-ace4-d5106bbdc113',
    :authentication       => 'plain',
    :enable_starttls_auto => true  }

  # Uncomment the following line to enable sample profiling (see https://github.com/tmm1/stackprof for details)
  # config.middleware.use StackProf::Middleware, enabled: true, mode: :cpu, interval: 100, save_every: 5
end
