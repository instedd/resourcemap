require 'spec_helper' 

describe "create_layer", :type => :request do 
 
  it "should create layer", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    page.save_screenshot 'edit_layer.png'
    collection = create_collection_for(@user)
    login_as (@user)
    visit collections_path
    sleep 2
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    click_link "Layers"
    click_button 'Add new layer'
    fill_in 'name', :with => 'Test'
   	click_button 'Add new text field'
   	fill_in 'field_name', :with => 'Test name'
   	fill_in 'code', :with => 'Codigo'
   	click_button 'Save layer'
   	expect(page).to have_content "Saving layer, please wait..."
   	sleep 2
   	expect(page).to have_content "Layer 'Test' successfully created"
   	page.save_screenshot "Create layer.png"
  end
end