if ENV["COVERAGE"]
  require 'simplecov'
  SimpleCov.formatter SimpleCov::Formatter::SimpleFormatter if ENV['CI']

  SimpleCov.start do
    load_profile "test_frameworks"

    add_filter %r{^/config/}
    add_filter %r{^/db/}

    add_group "Controllers", ["app/controllers"] + Dir["plugins/*/controllers"]
    # add_group "Channels", ["app/channels"] + Dir["plugins/*/channels"]
    add_group "Models", ["app/models"] + Dir["plugins/*/models"]
    add_group "Mailers", ["app/mailers"] + Dir["plugins/*/mailers"]
    add_group "Helpers", ["app/helpers"] + Dir["plugins/*/helpers"]
    add_group "Jobs", %w[app/jobs app/workers] + Dir["plugins/*/{jobs,workers}"]
    add_group "Libraries", ["lib/"] + Dir["plugins/*/lib"]

    track_files "{app,lib}/**/*.rb"
  end
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require File.expand_path("../../spec/blueprints", __FILE__)
require 'rspec/rails'
require 'capybara/rspec'
require 'shoulda-matchers'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}
Dir[Rails.root.join("spec/integration/spec/helpers/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  ###########
  #capybara
  config.include Warden::Test::Helpers
  config.include Capybara::DSL
  config.include Capybara::CustomFinders
  config.include Capybara::AccountHelper
  config.include Capybara::CollectionHelper
  config.include Capybara::SettingsHelper
  config.include Capybara::MailHelper
  config.define_derived_metadata(:file_path => /spec\/integration/) do |metadata|
    metadata[:type] ||= :integration
  end
  config.filter_run_excluding(js: true) unless config.filter_manager.inclusions[:js] || ENV["FEATURES"]

  Warden.test_mode!

  # Set the default timeout for Capybara to re-synchronize with Selenium
  Capybara.default_max_wait_time = (ENV['CAPYBARA_TIMEOUT'] || '5').to_i
  Capybara.javascript_driver = :selenium
  Capybara.default_selector = :css

  setup_capybara_docker_driver_if_needed

  config.before(:each) do |example|
    DatabaseCleaner.strategy = if Capybara.current_driver == :rack_test
      :transaction
    else
      [:deletion]
    end
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
    Timecop.return
    RedisCache.clear!
  end

  # Dismiss initial Telemetry configuration (for integration testing)
  config.before(:each) do
    InsteddTelemetry::Setting.set(:dismissed, true)
  end

  # Take screenshots on acceptance tests failures
  def take_screenshot(example)
    meta            = example.metadata
    filename        = File.basename(meta[:file_path])
    line_number     = meta[:line_number]
    screenshot_name = "screenshot-#{filename}-#{line_number}.png"

    page.save_screenshot(screenshot_name)

    puts meta[:full_description] + "\n  Screenshot: #{screenshot_name}"
  end

  config.after(:each, :js) do |example|
    take_screenshot(example) if example.exception.present?
  end



  ##########
  config.example_status_persistence_file_path = Rails.root.join("tmp/rspec").to_s

  # Uncomment to view full backtraces
  # config.backtrace_clean_patterns = []

  # Helper for ignoring blocks of tests
  def ignore(*args); end;

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false
  config.infer_spec_type_from_file_location!

  def stub_time(time)
    time = Time.parse time
    allow(Time).to receive(:now) { time }
  end

  def with_tmp_file(filename)
    file = "#{Dir.tmpdir}/#{filename}"
    yield file
    File.delete file
  end

  $test_count = 0

  def delete_all_elasticsearch_indices
    Elasticsearch::Client.new.indices.delete index: "collection_test_*"
  end

  # Delete all test before and after the suite
  config.before(:all) { delete_all_elasticsearch_indices }
  config.after(:all) { delete_all_elasticsearch_indices }

# Mock nuntium access and gateways management
  config.before(:each) do
    @nuntium = double("nuntium")
    allow(Nuntium).to receive(:new_from_config).and_return(@nuntium)
    allow(@nuntium).to receive(:create_channel)
    allow(@nuntium).to receive(:update_channel)
    allow(@nuntium).to receive(:delete_channel)
    allow_any_instance_of(Channel).to receive(:gateway_url).and_return(true)
    allow_any_instance_of(Channel).to receive(:handle_nuntium_channel_response).and_return(true)
  end

  module ActionController::TestCase::Behavior
    alias resource_map_get get

    def get(action, params: nil, session: nil, flash: nil)
      params ||= {}
      params[:locale] = :en
      resource_map_get(action, params: params, session: session, flash: flash)
    end
  end

  # Turn on all plugins by default
  module Settings
    CONFIG_SETTINGS = YAML.load_file(File.expand_path('../../config/settings.yml', __FILE__))

    def is_on?(plugin)
      true
    end

    def selected_plugins
      [self]
    end

    def method_missing(method_name)
      if method_name.to_s =~ /(\w+)\?$/
        true
      else
        CONFIG_SETTINGS[method_name.to_s]
      end
    end
  end
end
