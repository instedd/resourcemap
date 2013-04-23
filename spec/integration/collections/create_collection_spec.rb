require 'spec_helper' 

describe "create_collection" do 
 
  it "should create a collection", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    login_as (@user)
    visit collections_path
  	page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[3]/button').click
  	sleep 1
  	fill_in  "collection_name", :with => 'Coleccion de prueba'
  	click_button "Save"
  	sleep 1
  	page.save_screenshot "Create Collection.png"
  	page.should have_content("Collection Coleccion de prueba created")
  end
end