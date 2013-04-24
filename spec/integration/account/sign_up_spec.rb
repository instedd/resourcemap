require 'spec_helper' 

describe "sign_up" do 
 
  it "should sign up", js:true do
 	visit "/"
 	sleep 1
 	click_button "Sign up for free"
 	sleep 1
 	page.save_screenshot 'Sign_up.png'
 	page.has_content? "form#new_user"
  end
end