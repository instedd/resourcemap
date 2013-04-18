module AccountHelper
  def login_as(login, password)
    @driver.find_element(:link, "Log in").click
    @driver.find_element(:id, "user_email").clear
    @driver.find_element(:id, "user_email").send_keys login
    @driver.find_element(:id, "user_password").clear
    @driver.find_element(:id, "user_password").send_keys password
    @driver.find_element(:xpath, "//div[contains(@class, 'actions')]/button").click
  end

  def logout
    @driver.find_element(:xpath, "//div[contains(@id, 'User')]").click
    sleep 5
    @driver.find_element(:link, "Sign Out").click
    sleep 10
  end

  def create_account(login, password)
    @driver.find_element(:link, "Create account").click
    @driver.find_element(:id, "user_email").clear
    @driver.find_element(:id, "user_email").send_keys login
    @driver.find_element(:id, "user_password").clear
    @driver.find_element(:id, "user_password").send_keys password
    @driver.find_element(:id, "user_password_confirmation").clear
    @driver.find_element(:id, "user_password_confirmation").send_keys password
    @driver.find_element(:id, "user_phone_number").clear
    @driver.find_element(:id, "user_phone_number").send_keys "123789456"
    @driver.find_element(:xpath, "//div[contains(@class, 'actions')]/button").click
  end  
end
