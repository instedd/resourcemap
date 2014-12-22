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

  def check_admin_rights
    find(:xpath, '//*[@id="memberPermissionsTable"]/table/tbody/tr[5]/td/div/div[5]/input').click
  end

  def click_on(link)
    find(:xpath, link).click
  end

end