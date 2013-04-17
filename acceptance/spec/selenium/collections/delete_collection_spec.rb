require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  event = unique('event')
  get "/"
  login_as "mmuller+9889@manas.com.ar", "123456789"
  create_event :name => event, :volunteers_quantity => "4",:description => "a single house fire. 3 pets.", :address => "san mateo"
  go_to_my_events
  @driver.find_element(:xpath, "//tbody/tr[2]/td").click
  @driver.find_element(:xpath, "//div[contains(@id, 'mission_actions')]/form[3]/button").click
  a = @driver.switch_to.alert
  a.accept
  sleep 5
  go_to_my_events
  i_should_not_see event
end
