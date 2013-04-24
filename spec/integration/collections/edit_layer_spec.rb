require 'spec_helper' 

describe "edit_layer" do 
 
  it "should edit layer", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    page.save_screenshot 'edit_layer.png'
    collection = create_collection_for(@user)
    layer = create_layer_for (collection)
    login_as (@user)
    visit collections_path
  end
  
end