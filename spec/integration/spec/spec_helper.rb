require "rubygems"
require "rspec/autorun"
require "selenium-webdriver"
Dir[File.expand_path("../helpers/*.rb", __FILE__)].each do |file|
  require file
end

def acceptance_test(options ={},  &block)
  name = caller[0]
  name = /.*(\/|\\)(.*)\.rb/.
  match(name)[2].gsub('_', ' ')
  describe name do
    include AccountHelper
    include CollectionsHelper
    include SeleniumHelper
    include SettingsHelper
    include MailHelper

    unless options.has_key?(:open_browser) && !options[:open_browser]
      before(:each) do
        @driver = Selenium::WebDriver.for :firefox
        @driver.manage.timeouts.implicit_wait = 60
      end

  before(:each) { sleep 5; puts "durmiendo" }


      after(:each) do
        @driver.quit
      end
    end

    it name, &block
  end
end
