require 'spec_helper' 

describe "collections" do 
 
  it "should edit site Select many values", js:true do   
    
    current_user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for (current_user)
    member = User.make(:email => 'member@member.com')
    member.memberships.make collection: collection
    layer = create_layer_for (collection)
    select_many = layer.select_many_fields.make(:name => 'Select Many', :code => 'selmany', config: {"options"=>[{"id"=>1, "code"=>"firstopcod", "label"=>"first op"}, {"id"=>2, "code"=>"secopcod", "label"=>"second op"}, {"id"=>3, "code"=>"anotheropcod", "label"=>"another op"}], "next_id"=>4})
    collection.sites.make :id => 8902, :name => 'Type: Select Many', properties: { select_many.es_code => [2,3] }
    login_as (current_user)
    visit collections_path
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    click_link 'Edit Site'
    sleep 50
    click_link "Add more"
    find(:xpath, "//div[@class='tablescroll']/table/tbody/tr/td/div[12]/ul[@class='taglist']/li[1]/a").click
    sleep 2
    # select('first option', :from => 'select-one-input-selone')
    # click_button 'Done'
    # sleep 3 
    # page.should_not have_content 'second option'
    # page.should have_content 'first option'
    # page.save_screenshot "Edit_site_selman_value.png"
  end
end