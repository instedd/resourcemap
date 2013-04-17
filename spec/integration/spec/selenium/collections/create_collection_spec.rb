require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  get "/"
  volunteer_name =  unique ('Volunteer')
  voice_number =  unique ('999')
  sms_number =  unique ('999')
  login_as "mmuller+9889@manas.com.ar", "123456789"
  @driver.find_element(:link, "Volunteers").click
  @driver.find_element(:xpath, "//h1/form/button").click
  @driver.find_element(:id, "volunteer_name").clear
  @driver.find_element(:id, "volunteer_name").send_keys volunteer_name
  @driver.find_element(:id, "volunteer_voice_number").clear
  @driver.find_element(:id, "volunteer_voice_number").send_keys voice_number
  @driver.find_element(:id, "volunteer_sms_number").clear
  @driver.find_element(:id, "volunteer_sms_number").send_keys sms_number
  @driver.find_element(:id, "volunteer_address").clear
  @driver.find_element(:id, "volunteer_address").send_keys "San Mateo"
  @driver.find_element(:id, "volunteer_address").send_keys
  @driver.find_element(:class, "superblyTagfieldDiv").clear
  @driver.find_element(:class, "superblyTagfieldDiv").send_keys "San Mateo"
  sleep 5
  @driver.find_element(:xpath, "//div[contains(@class, 'bottom-actions')]/button").click
  sleep 5
end
