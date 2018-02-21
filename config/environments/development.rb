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
  if Settings.smtp.present?
    smtp_settings = {}.tap do |settings|
      settings[:address]              = Settings.smtp["address"] if Settings.smtp["address"].present?
      settings[:port]                 = Settings.smtp["port"] if Settings.smtp["port"].present?
      settings[:domain]               = Settings.smtp["domain"] if Settings.smtp["domain"].present?
      settings[:user_name]            = Settings.smtp["user_name"] if Settings.smtp["user_name"].present?
      settings[:password]             = Settings.smtp["password"] if Settings.smtp["password"].present?
      settings[:authentication]       = Settings.smtp["authentication"] if Settings.smtp["authentication"].present?
      settings[:enable_starttls_auto] = Settings.smtp["enable_starttls_auto"] if Settings.smtp["enable_starttls_auto"].present?
    end
    if smtp_settings.present?
      config.action_mailer.delivery_method = :smtp
      config.action_mailer.smtp_settings = smtp_settings
    end
  end

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = false # if true, the thin server was too slow in docker environment

  # Uncomment the following line to enable sample profiling (see https://github.com/tmm1/stackprof for details)
  # config.middleware.use StackProf::Middleware, enabled: true, mode: :cpu, interval: 100, save_every: 5

  config.web_console.whitelisted_ips = '0.0.0.0/0'
end
