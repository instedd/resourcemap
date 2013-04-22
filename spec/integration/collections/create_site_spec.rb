require 'spec_helper' 

describe "create_site" do 
 
  it "create site", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    page.save_screenshot 'create_collection.png'
    @collection = create_collection_for(@user) 
    login_as (@user)
    visit collections_path
  end
end