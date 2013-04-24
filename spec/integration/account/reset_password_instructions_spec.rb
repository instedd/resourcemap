require 'spec_helper' 

describe "reset_password" do 

 it "should reset password", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    visit collections_path
    within "form#new_user" do 
      fill_in  "Email", :with => @user.email 
    end
  	sleep 4
  	click_link 'Reset it'
  	sleep 2
  	fill_in "user_email", :with => @user.email
  	click_button "Send me reset password instructions"
  	sleep 2
  	page.save_screenshot 'reset_password.png'
  	page.should have_content 'You will receive an email with instructions about how to reset your password in a few minutes.'
  end
end
