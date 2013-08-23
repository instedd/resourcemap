require 'spec_helper' 

describe "import_layer" do 
 
  it "should create layer", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    page.save_screenshot 'import_layer.png'
    collection = create_collection_for(@user)
    layer = create_layer_for (collection)
    field = create_field_for (layer)
    login_as (@user)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[3]/button').click
    sleep 1
    fill_in  "collection_name", :with => 'Coleccion de prueba'
    click_button "Save"
    sleep 1
    click_link "Layers"
    page.find(:xpath, '//div[@class="tabsline"]/div[@id="layers-main"]/div[2]/img').click
   	sleep 1
    click_button 'Import'
    sleep 1
    page.should have_content 'Imported layers from Central Hospital'
    sleep 1
   	page.should have_content "Central Hospital Layer 1 Field"
   	page.save_screenshot "Import_layers.png"
  end
end