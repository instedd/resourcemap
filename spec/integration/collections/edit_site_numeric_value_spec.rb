require 'spec_helper' 

describe "collections" do 
 
  it "should edit site Numeric values", js:true do   
    
    current_user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for (current_user)
    member = User.make(:email => 'member@member.com')
    member.memberships.make collection: collection
    layer = create_layer_for (collection)
    numeric = layer.numeric_fields.make(:name => 'Numeric', :code => 'numeric')
    collection.sites.make properties: { numeric.es_code => '876' }
    login_as (current_user)
    visit collections_path
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    click_link 'Edit Site'
    sleep 2
    fill_in 'numeric-input-numeric', :with => '1234567890'
    click_button 'Done'
    sleep 3 
    page.should_not have_content '876'
    page.should have_content '1234567890'
    page.save_screenshot "Edit_site_Numeric_value.png"
  end
end