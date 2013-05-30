require 'spec_helper' 

describe "collections" do 
 
  it "should edit site Select One values", js:true do   
    
    current_user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for (current_user)
    member = User.make(:email => 'member@member.com')
    member.memberships.make collection: collection
    layer = create_layer_for (collection)
    select_one = layer.select_one_fields.make(:name => 'Select One', :code => 'selone', config: {"options"=>[{"id"=>1, "code"=>"option code 1", "label"=>"first option"},{"id"=>2, "code"=>"option code 2", "label"=>"second option"}], "next_id"=>3})
    collection.sites.make :name => 'Type: Select One', properties: { select_one.es_code => 2 }
    login_as (current_user)
    visit collections_path
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    click_link 'Edit Site'
    sleep 5
    select('first option', :from => 'select-one-input-selone')
    click_button 'Done'
    sleep 3 
    page.should_not have_content 'second option'
    page.should have_content 'first option'
    page.save_screenshot "Edit_site_selone_value.png"
  end
end