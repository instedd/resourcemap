require 'spec_helper' 

describe "snapshots" do 
 
  it "should not edit site using snapshot", js:true do
    p "This test fails because https://bitbucket.org/instedd/resource_map/issue/401/displayed-number-of-snapshots-sites-is"
    user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for (user)
    create_site_for (collection)
    snap= Snapshot.make :collection => collection
    UserSnapshot.make :user => user, :snapshot => snap
    login_as (user)
    visit collections_path
    sleep 3
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr/td/div[2]/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    sleep 3
    page.should_not have_content "Edit"
    page.should have_content "You are currently viewing this collection's data as it was on snapshot mina. To make changes, please"
    page.save_screenshot 'Edit_site_snapshot.png'
  end
  
end