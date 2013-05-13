require 'spec_helper' 

describe "sites" do 
 
  it "should edit site yes/no value", js:true do   
    
    current_user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for (current_user)
    member = User.make(:email => 'member@member.com')
    member.memberships.make collection: collection
    layer = create_layer_for (collection)
    yes_no = layer.yes_no_fields.make(:name => 'Y/N', :code => 'y/n')
    collection.sites.make properties: { yes_no.es_code => 1 }
    login_as (current_user)
    visit collections_path
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    click_link 'Edit Site'
    sleep 2
    page.uncheck('yes-no-input-y/n')
    click_button 'Done'
    page.should_not have_content ('yes')
    page.should have_content ('no')
  end

end

