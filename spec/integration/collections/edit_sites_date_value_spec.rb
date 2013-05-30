require 'spec_helper' 

describe "collections" do 
 
  it "should edit site Text values", js:true do   
    
    current_user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for (current_user)
    member = User.make(:email => 'member@member.com')
    member.memberships.make collection: collection
    layer = create_layer_for (collection)
    date = layer.date_fields.make(:name => 'Date', :code => 'date')
    collection.sites.make :name => 'Type: Date', properties: { date.es_code => '2013-04-06T00:00:00Z'}
    login_as (current_user)
    visit collections_path
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    click_link 'Edit Site'
    sleep 25
    fill_in 'valueUI', :with => '12/7/2013'
    click_button 'Done'
    sleep 3 
    page.should have_content '12/7/2013'
    page.save_screenshot "Edit_site_Date_value.png"
  end
end
