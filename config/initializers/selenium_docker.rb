unless ENV['SELENIUM_URL'].nil? || ENV['SELENIUM_URL'].empty?
  require 'capybara/rspec'

  Capybara.register_driver :docker_firefox do |app|

    Capybara::Selenium::Driver.new(app, {
      browser: :remote,
      url: "#{ENV['SELENIUM_URL']}/wd/hub",
      desired_capabilities: Selenium::WebDriver::Remote::Capabilities.firefox
    })
  end
end

def setup_capybara_docker_driver_if_needed
  unless ENV['SELENIUM_URL'].nil? || ENV['SELENIUM_URL'].empty?
    ip = `/sbin/ip route|awk '/scope/ { print $9 }'`.gsub("\n", "")

    Capybara.javascript_driver = :docker_firefox
    Capybara.server_port = 55555
    Capybara.server_host = "#{ip}"
    Capybara.app_host = "http://#{ip}:#{Capybara.server_port}"
  end
end
