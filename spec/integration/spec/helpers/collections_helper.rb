module CollectionsHelper
  def go_to_my_collections
    @driver.find_element(:link, "Collections").click
  end

  def create_event(options = {})
    title = unique('Collection')
    @driver.find_element(:xpath, "//td[contains(@class, 'add')]").click
    @driver.find_element(:id, "name").clear
    @driver.find_element(:id, "name").send_keys options[:name]
    @driver.find_element(:id, "reason").clear
    @driver.find_element(:id, "reason").send_keys options[:description]
    @driver.find_element(:id, "address").clear
    @driver.find_element(:id, "address").send_keys options[:address]
    @driver.find_element(:xpath, "//button[contains(@id, 'search_address')]").click
    #i_should_not_see "This event has not been initialized, complete all the fields and start recruiting" 
    sleep 5
    @driver.find_element(:xpath, "//div[contains(@id, 'mission_status')]/button").click
    sleep 10
    #i_should_see 
  end

 def switch_to
  @switch_to ||= WebDriver::TargetLocator.new(bridge)
  end
end
