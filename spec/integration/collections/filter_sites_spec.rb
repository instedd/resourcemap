require 'spec_helper' 

describe "filter_sites" do 
 
  it "should filter sites", js:true do
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
    find('.refine').click
    find(:xpath, '//div[@class="refine-popup box"]/div[3]').click
    find(:xpath, '//div[@class="refine-popup box"]/div[4]/input').set("fra")
    find(:xpath, '//div[@class="refine-popup box"]/div[4]/a').click
    sleep 3
    page.save_screenshot 'Filter_sites.png'
    page.should have_content 'Show sites where Central Hospital Layer 1 Field starts with "fra" '
  end  
end