require 'spec_helper' 

describe "delete_collection_sites" do 
 
  it "should delete sites of a collection", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user) 
    login_as (@user)
    visit collections_path
  	page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
  	page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
  	click_link "Delete this collection's sites"
  	click_link "Confirm"
    sleep 2
  	page.save_screenshot "Delete Collection Sites.png"
    sleep 6
  	page.should have_content "Collection Central Hospital's sites deleted"
  end
end