require 'spec_helper' 

describe "Accounts" do 

  it "should create an account", js:true do
   User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
  end

end







