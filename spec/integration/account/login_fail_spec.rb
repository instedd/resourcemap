require 'spec_helper' 

describe "login_fail" do 

  it "should fail to login", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    visit collections_path
    within "form#new_user" do 
      fill_in  "Email", :with => @user.email 
      fill_in  "Password", :with => '12345098765'
      click_button('Log In')
    end 
    sleep 2
    page.save_screenshot 'login_fail.png'
    page.should have_content("Invalid email or password.")
  end

end