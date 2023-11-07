require "rspec/retry"

RSpec.configure do |config|
  config.verbose_retry = true
  config.display_try_failure_messages = true
  config.default_sleep_interval = 5

  config.around :each, :js do |ex|
    ex.run_with_retry retry: 5
  end

  config.retry_callback = proc do |ex|
    Capybara.reset! if ex.metadata[:js]
  end
end
