require 'spec_helper' 

describe "log_out" do 
 
  it "should log out", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    login_as (@user)
    visit collections_path
    find_by_id('User').click
    click_link('Sign Out')
    sleep 3
    page.save_screenshot 'Log_out.png'
    page.should have_content 'Signed out successfully'
  end
end
