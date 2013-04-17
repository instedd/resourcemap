require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  get "/"
  login_as "mmuller+3000@manas.com.ar", "123456789"
  sleep 5
  @driver.find_element(:xpath, "//div[contains(@id, 'User')]").click
  sleep 5
  @driver.find_element(:link, "My Account").click
  @driver.find_element(:id, "user_current_password").clear
  @driver.find_element(:id, "user_current_password").send_keys "123456789"
  @driver.find_element(:link, "Change my password").click
  @driver.find_element(:id, "user_password").clear
  @driver.find_element(:id, "user_password").send_keys "123456789"
  @driver.find_element(:id, "user_password_confirmation").clear
  @driver.find_element(:id, "user_password_confirmation").send_keys "123456789"
  @driver.find_element(:xpath, "//div[contains(@class, 'registration bottom-actions')]/button").click
  i_should_see "You updated your account successfully."
end
