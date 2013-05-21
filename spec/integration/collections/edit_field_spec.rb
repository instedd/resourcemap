require 'spec_helper' 

describe "edit_field" do 
 
  it "should edit field", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    page.save_screenshot 'edit_layer.png'
    collection = create_collection_for(@user)
    layer = create_layer_for (collection)
    field = create_field_for (layer)
    login_as (@user)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    click_link "Layers"
    sleep 2
    click_button "Edit"
    sleep 2
    fill_in 'field_name', :with => 'Test Field'
    sleep 5
    click_button 'Save layer'
    sleep 5
    page.save_screenshot 'Edit_field.png'
    page.should have_content "Layer 'Central Hospital Layer 1' successfully saved"
  end
end