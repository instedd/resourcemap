require 'spec_helper' 

describe "search" do 
 
  it "should search", js:true do
    user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    page.save_screenshot 'filter_sites.png'
    collection = create_collection_for (user)
    layer = create_layer_for (collection)
    field = create_field_for (layer)
    10.times { collection.sites.make properties: { field.es_code => 'fra' } }
    10.times { collection.sites.make properties: { field.es_code => 'ter' } }
    10.times { collection.sites.make properties: { field.es_code => 'nity' } }
    login_as (user)
    visit collections_path
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    fill_in 'search', :with => "Aida Rohan\n"
    sleep 10
    page.save_screenshot 'Search.png'
    page.should have_content 'Aida Rohan'
    page.should have_no_content 'Alek Ortiz'
  end
end