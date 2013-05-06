require 'spec_helper' 

describe "collections" do 
 
  it "should edit site Identifier values", js:true do   
    
    current_user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for (current_user)
    member = User.make(:email => 'member@member.com')
    member.memberships.make collection: collection
    layer = create_layer_for (collection)
    identifier = layer.identifier_fields.make(:name => 'ID', :code => 'id')
    collection.sites.make properties: { identifier.es_code => 'ID4567HJL' }
    login_as (current_user)
    visit collections_path
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    click_link 'Edit Site'
    sleep 3
    fill_in 'identifier-input-id', :with => 'GB120712MB'
    click_button 'Done'
    sleep 3 
    page.should_not have_content 'ID4567HJL'
    page.should have_content 'GB120712MB'
    page.save_screenshot "Edit_site_identifier_value.png"
  end
end
