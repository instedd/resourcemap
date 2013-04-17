require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  get "/users/sign_in"
  @driver.find_element(:link, "Reset it").click
  #login_as "mmuller+3000@manas.com.ar", "123456789"
  @driver.find_element(:id, "user_email").clear
  @driver.find_element(:id, "user_email").send_keys "testingstg+20130410111837@gmail.com"
  @driver.find_element(:xpath, "//div[contains(@class, 'actions')]/button").click
  i_should_see "You will receive an email with instructions about how to reset your password in a few minutes."
  mail_body = get_mail
  link = get_link mail_body
  sleep 10
  get link
  sleep 5
  @driver.find_element(:id, "user_password").clear
  @driver.find_element(:id, "user_password").send_keys "123456789"
  @driver.find_element(:id, "user_password_confirmation").clear
  @driver.find_element(:id, "user_password_confirmation").send_keys "123456789"
  @driver.find_element(:xpath, "//div[contains(@class, 'actions')]/button").click
  i_should_see "Your password was changed successfully. You are now signed in."
end 	