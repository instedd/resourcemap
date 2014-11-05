require 'spec_helper'

describe "login", :type => :request do

  it "should login", js:true do
    user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    visit collections_path
    click_link 'Log in'
    within login_form do
      fill_in  "Email", :with => user.email
      fill_in  "Password", :with => "1234567"
      click_button('Log In')
    end
    page.save_screenshot 'login.png'
    expect(page).to have_content('Signed in successfully.')
  end

end