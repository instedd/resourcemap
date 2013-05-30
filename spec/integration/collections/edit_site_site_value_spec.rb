require 'spec_helper' 

describe "sites" do 
 
  it "should edit site Site value", js:true do   

    current_user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for (current_user)
    member = User.make(:email => 'member@member.com')
    member.memberships.make collection: collection
    layer = create_layer_for (collection)
    site_field = layer.site_fields.make(:name => 'Site', :code => 'site')
    site1 = collection.sites.make :name => 'First Site'
    collection.sites.make :name => 'Second Site'
    collection.sites.make :name => 'Type: Site', properties: { site_field.es_code => site1.id }
    login_as (current_user)
    visit collections_path
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[3]/td/button').click
    page.should have_content 'First Site'
    page.should_not have_content 'Second Site'
    click_link 'Edit Site'
    sleep 3
    fill_in 'site-input-site', :with => "Second Site\n" 
    sleep 3
    page.should_not have_content 'First Site'
    page.should have_content 'Second Site'
    page.save_screenshot "Edit_site_Site_value.png"

  end

end