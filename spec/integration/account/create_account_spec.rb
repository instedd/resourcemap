require 'spec_helper'

describe "create_account", :type => :request do

  it "should create an account", js:true do
 	visit "/"
 	click_link 'Create account'
 	page.has_content? "form#new_user"
  within login_form do
      fill_in  "Email", :with => 'user@manas.com.ar'
      fill_in  "Password", :with => "1234567"
      fill_in  "Password confirmation", :with => "1234567"
      fill_in  "Phone number", :with => "1234567"
      click_button ('Create account')
    end
  end
end