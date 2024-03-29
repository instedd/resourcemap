# encoding: utf-8
require File.expand_path('../boot', __FILE__)

require 'rails/all'

require "openid"
require 'openid/extensions/sreg'
require 'openid/extensions/pape'
require 'openid/store/filesystem'

Bundler.require(:default, Rails.env)

module ResourceMap
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += Dir["#{config.root}/plugins/"]
    config.autoload_paths += Dir["#{config.root}/plugins/*/{helpers,controllers,models,workers}"]

    # FIXME: add strong parameters filters to all controllers
    config.action_controller.permit_all_parameters = true

    # Load all Field classes to make associations like "text_fields" and "numeric_fields" work
    config.to_prepare do
      Dir[ File.expand_path(Rails.root.join("app/models/field/*.rb")) ].each do |file|
        require_dependency file
      end
    end

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Do not swallow errors in after_commit/after_rollback callbacks (Rails 4.2).
    config.active_record.raise_in_transactional_callbacks = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.action_mailer.delivery_method = :sendmail
    config.google_analytics = 'UA-17030081-1'

    config.version_name = File.read('VERSION').strip rescue "Development"
    config.revision = File.read('REVISION').strip rescue "Development"

    # Languages
    config.available_locales = {
      :en => "English",
      :fr => "Français",
    }

    # Default language
    config.default_locale = :en

    # Gettext configuration
    FastGettext.add_text_domain 'app', :path => 'locale', :type => :po, :ignore_fuzzy => true, :report_warning => false
    config.i18n.enforce_available_locales = true

    FastGettext.default_available_locales = config.available_locales.keys.map(&:to_s)
    FastGettext.default_text_domain = 'app'
    FastGettext.default_locale = 'en'
  end

end

Haml::MagicTranslations.enable(:i18n)
I18n.load_path += Dir["locale/en/*.{po}"]
I18n.load_path += Dir["locale/fr/*.{po}"]
