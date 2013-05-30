require 'spec_helper' 

describe "collections" do 
 
  it "should edit site User values", js:true do   
    
    current_user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for (current_user)
    member = User.make(:email => 'member@member.com')
    member.memberships.make collection: collection
    layer = create_layer_for (collection)
    user_field = layer.user_fields.make(:name => 'User', :code => 'user')
    collection.sites.make :name => 'Type: User', properties: { user_field.es_code => 'member@member.com' }
    login_as (current_user)
    visit collections_path
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    click_link 'Edit Site'
    sleep 2
    fill_in 'user-input-user', :with => 'user@manas.com.ar'
    click_button 'Done'
    sleep 3 
    page.should_not have_content 'member@member.com'
    page.should have_content 'user@manas.com.ar'
    page.save_screenshot "Edit_site_user_value.png"
  end
end
