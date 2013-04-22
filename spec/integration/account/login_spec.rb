require 'spec_helper' 

describe "login" do 

  it "should login", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    visit collections_path
    within "form#new_user" do 
      fill_in  "Email", :with => @user.email 
      fill_in  "Password", :with => @user.password
      click_button('Log In')
    end 
    page.save_screenshot 'login.png'
    page.should have_content("Signed in successfully")
  end

end