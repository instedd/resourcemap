require 'spec_helper'

describe "reset_password", :type => :request do

 pending "should reset password", js:true do
    user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    visit collections_path
    click_link 'Log in'

    within login_form do
      fill_in  "Email", :with => user.email
      fill_in  "Password", :with => "Password01"
    end

  	click_link 'Reset it'
  	fill_in "user_email", :with => user.email
  	click_button "Send me reset password instructions"
  	page.save_screenshot 'reset_password.png'
  	expect(page).to have_content 'You will receive an email with instructions about how to reset your password in a few minutes.'
  end
end
