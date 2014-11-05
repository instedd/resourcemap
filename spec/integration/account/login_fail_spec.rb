require 'spec_helper'

describe "login_fail", :type => :request do

  it "should fail to login", js:true do
    user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    visit collections_path
    click_link 'Log in'
    within login_form do
      fill_in  "Email", :with => user.email
      fill_in  "Password", :with => "Password01"
      click_button('Log In')
    end
    page.save_screenshot 'login_fail.png'
    expect(page).to have_content("Invalid email or password.")
  end

end