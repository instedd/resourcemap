module Capybara::CustomFinders

  def filter(name)
    "div[data-filter-type=\"#{name.camelcase}\"]"
  end

  def confirm_popup
  	page.driver.browser.switch_to.alert.accept
  end
  
  def dismiss_popup
  	page.driver.browser.switch_to.alert.dismiss
  end
end