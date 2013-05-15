require 'spec_helper' 

describe "layers" do 
 
  it "should sort layer", js:true do
    user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for(user)
    layers = %w{ Beds Rooms }  
    layers.each do |layer|
      lay = collection.layers.make(:name => layer)
      lay.text_fields.make
    end 
    login_as (user)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    click_link "Layers"
    click_button "Move layer down"
    page.find(:xpath, '//div[@id="layers-main"]/div[1]/button').click
    page.should have_content layers[0]
    page.save_screenshot 'Sort_layer.png'
  end

end