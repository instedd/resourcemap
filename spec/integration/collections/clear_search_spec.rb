require 'spec_helper' 

describe "clear_search" do 
 
  it "should clear search", js:true do
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
    page.should have_content 'Aida Rohan'
    sleep 2
    click_link 'clear search'
    page.save_screenshot 'Clear_search.png'
    page.should have_content 'Alek Ortiz'
  end
end