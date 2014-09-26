require 'spec_helper' 

describe "delete_layer", :type => :request do 
 
  it "should delete layer", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    page.save_screenshot 'edit_layer.png'
    collection = create_collection_for(@user)
    layer = create_layer_for (collection)
    field = create_field_for (layer)
    login_as (@user)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    sleep 2
    click_link "Layers"
    click_button "Remove layer"
    sleep 1
    page.driver.browser.switch_to.alert.accept
    sleep 2     
    page.save_screenshot 'Delete_layer.png'
    expect(page).to have_content "Layer 'Central Hospital Layer 1' successfully deleted"
  end  
end