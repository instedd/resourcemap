require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  event = unique('event')
  get "/"
  login_as "mmuller+9889@manas.com.ar", "123456789"
  go_to_my_events 
  sleep 5
  @driver.find_element(:xpath, "//div[contains(@id, 'mission_status')]/button").click
  sleep 4
  i_should_see "Resume recruiting" 
end
