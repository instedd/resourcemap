require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  get "/"
  login_as "germanbatiston+01@gmail.com", "123456789"
  sleep 5
  find_element(:xpath, "//div[contains(@id, 'User')]").click
  sleep 5
  find_element(:link, "Settings").click
  sleep 5
  find_element(:link, "Cancel my account").click
  # @driver.confirm_popup
end
