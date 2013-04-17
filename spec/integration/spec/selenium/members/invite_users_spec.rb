require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  email = unique('testingstg@gmail.com')
  get "/"
  login_as "mmuller+9889@manas.com.ar", "123456789"
  sleep 5
  @driver.find_element(:link, "Invite new users").click
  @driver.find_element(:id, "user_email").clear
  @driver.find_element(:id, "user_email").send_keys email
  p email
  sleep 10
  @driver.find_element(:xpath, "//div[contains(@id, 'invitation_bubble')]/form/button").click
  sleep 5
  logout
  #i_should_see "Signed out successfully."
  #i_should_see "An invitation email has been sent to #{email}"
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
  sleep 5
  #i_should_see"Your account was successfully confirmed. You are now signed in."
end