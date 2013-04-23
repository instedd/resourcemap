require 'spec_helper' 

describe "unload_snapshot" do 
 
  it "should go back to present time", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user) 
    login_as (@user)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    fill_in 'snapshot_name', :with => 'Snapshot3'
    click_button 'Take new snapshot'
    sleep 2 
    page.should have_content 'Snapshot3'
    choose ('name_Snapshot3')
    sleep 1
    page.should have_content 'Snapshot Snapshot3 loaded'
    choose ('name_')
    sleep 1 
    page.save_screenshot ('Present_time.png')
    page.should have_content ('Snapshot Snapshot3 unloaded')
  end
end
