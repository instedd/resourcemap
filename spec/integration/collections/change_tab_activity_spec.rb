require 'spec_helper' 

describe "change_tab_activity" do 
 
  it "should change to activity tab", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    login_as (@user)
    visit collections_path
    click_link ('Activity')
    sleep 3
    page.save_screenshot 'TabActivity'
    sleep 2
    page.should have_content ('Activity')
  end
end