require 'spec_helper' 

describe "snapshots" do 
 
  it "should not edit layer with snapshot", js:true do
    sleep 5
    user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for(user)
    layer = create_layer_for (collection)
    field = create_field_for (layer)
    snap= Snapshot.make(:collection => collection, :name => 'Felurian')
    UserSnapshot.make :user => user, :snapshot => snap
    login_as (user)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr/td/div[2]/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    sleep 2
    choose ('name_Felurian')
    sleep 2
    click_link "Layers"
    sleep 2 
    page.should_not have_content "Edit"
    sleep 2
    page.should have_content "You are currently viewing this collection's data as it was on snapshot Felurian. To make changes, please"
    page.save_screenshot 'Edit_layer_snapshot.png'
  end  

end