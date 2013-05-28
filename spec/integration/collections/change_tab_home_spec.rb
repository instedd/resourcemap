require 'spec_helper' 

describe "change_tab_home" do 
 
  it "should change to home tab", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    login_as (@user)
    visit collections_path
    page.find(:xpath, '//div[@id="NavMenu"]/ul/li[2]/a').click
    sleep 3
    page.save_screenshot 'TabHome'
    sleep 3
    page.should have_content ('Make better decisions')
  end
end