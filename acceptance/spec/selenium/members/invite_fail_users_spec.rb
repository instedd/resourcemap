require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  get "/"
  login_as "mmuller+9889@manas.com.ar", "123456789"
  sleep 5
  @driver.find_element(:link, "Invite new users").click
  @driver.find_element(:id, "user_email").clear
  @driver.find_element(:id, "user_email").send_keys "mmuller+9889@manas.com.ar"
  sleep 5
  @driver.find_element(:xpath, "//div[contains(@id, 'invitation_bubble')]/form/button").click
  sleep 5
  i_should_see "Email has already been taken"
end