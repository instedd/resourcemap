require 'spec_helper' 

describe "collections" do 
 
  it "should edit site Text values", js:true do   
    
    current_user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for (current_user)
    member = User.make(:email => 'member@member.com')
    member.memberships.make collection: collection
    layer = create_layer_for (collection)
    email = layer.email_fields.make(:name => 'Email', :code => 'email')
    collection.sites.make properties: { email.es_code => 'man@as.com' }
    login_as (current_user)
    visit collections_path
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    click_link 'Edit Site'
    sleep 2
    fill_in 'email-input-email', :with => 'manas@manas.com'
    click_button 'Done'
    sleep 3 
    page.should_not have_content 'man@as.com'
    page.should have_content 'manas@manas.com'
    page.save_screenshot "Edit_site_Email_value.png"
  end
end
