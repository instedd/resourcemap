require 'spec_helper' 

describe "Accounts" do 

  it "should create an account", js:true do
   @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
   login_as (@user)
   visit collections_path
  end

end