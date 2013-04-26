require 'spec_helper' 

describe "create_snapshot_fail" do 
 
  it "should not take a snapshot", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user) 
    login_as (@user)
    visit collections_path
  	page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
  	page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
  	sleep 2 
    click_button 'Take new snapshot'
    sleep 2
  	page.save_screenshot 'Create_snapshot_fail.png'
    page.should have_content "Name can't be blank"
  	page.should have_content 'Snapshot could not be created'
  end
end
