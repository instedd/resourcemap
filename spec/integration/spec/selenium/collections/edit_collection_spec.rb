require File.expand_path('../../../spec_helper', __FILE__)

acceptance_test do
  event = "EventToAddRecruitees"
  get "/"
  login_as "mmuller+9889@manas.com.ar", "123456789"
  create_event :name => event, :volunteers_quantity => "4",:description => "a single house fire. 3 pets.", :address => "new york"
  i_should_see "4"
  #Pause the event
  @driver.find_element(:xpath, "//div[contains(@id, 'mission_status')]/button").click
  sleep 5
  i_should_see "Resume recruiting"
  #Add recruitees
  @driver.find_element(:xpath, "//span[contains(@class, 'ux-nstep w06')]/button[2]").click
  sleep 10
  i_should_see "6"
end

