module SettingsHelper
  def go_to_my_settings
    @driver.find_element(:link, "Settings").click
  end
end
