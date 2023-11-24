require 'spec_helper'

describe "create_collection", :type => :request do

  it "should not create a collection", js:true do
    @user = User.make!(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    login_as (@user)
    visit collections_path
  	page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[3]/button').click

  	click_button "Save"

  	page.save_screenshot "Create Collection_fail.png"
  	expect(page).to have_content("Name can't be blank")
  end
end