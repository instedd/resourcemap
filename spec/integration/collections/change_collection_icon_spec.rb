require 'spec_helper' 

describe "change_collections_icon" do 
 
it " should change a collections icon", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user) 
    login_as (@user)
    visit collections_path
    sleep 2
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    click_link "Settings"
    sleep 3
 	  page.find(".army").click 
    sleep 2
   	click_button "Save"
  	page.save_screenshot "Edit Collections icon.png"
  	page.should have_content "Collection Central Hospital updated"
  end
end