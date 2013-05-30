require 'spec_helper' 

describe "view_table_mode" do 
 
it "should change to table mode view", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user) 
    login_as (@user)
    visit collections_path
    sleep 2
    find(:xpath, '//div[@id="right-panel"]/div[1]/button[2]').click
    sleep 2
    has_content?("icon_button ftable right active")
    sleep 2
    page.save_screenshot 'Table view.png'
  end
end