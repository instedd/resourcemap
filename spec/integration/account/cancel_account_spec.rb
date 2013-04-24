require 'spec_helper' 

describe "cancel_account" do 
 
it " should cancel account", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user) 
    login_as (@user)
    visit collections_path
    sleep 2
    find(:xpath, '//div[@id="toolbar"]/ul[2]/li[2]/a').click
    click_link 'Cancel my account'
    page.driver.browser.switch_to.alert.accept 
    sleep 2
    page.save_screenshot 'Cancel_account.png'
    page.should have_content 'Bye! Your account was successfully cancelled. We hope to see you again soon.'
  end
end