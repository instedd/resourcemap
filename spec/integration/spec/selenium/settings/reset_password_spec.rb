require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  get "/"
  login_as "mmuller+9889@manas.com.ar", "123456789"
  i_should_see "Signed in successfully."
  @driver.find_element(:xpath, "//ul[contains(@class, 'RightMenu')]/li[2]/a").click
  @driver.find_element(:id, "user_current_password").clear
  @driver.find_element(:id, "user_current_password").send_keys "123456789"
  @driver.find_element(:link, "Change my password").click
  @driver.find_element(:id, "user_password").clear
  @driver.find_element(:id, "user_password").send_keys "123456789"
  @driver.find_element(:id, "user_password_confirmation").clear
  @driver.find_element(:id, "user_password_confirmation").send_keys "123456789"
  @driver.find_element(:xpath, "//button[contains(@class, 'white')]").click
  i_should_see "You updated your account successfully." 
end
