require 'spec_helper' 

describe "snapshots" do 
 
  it "should not create site using snapshot", js:true do
    user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for(user) 
    snap= Snapshot.make :collection => collection
    UserSnapshot.make :user => user, :snapshot => snap
    login_as (user)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr/td/div[2]/button').click
    sleep 3
  	page.should_not have_content "Create Site"
    page.should have_content "You are currently viewing this collection's data as it was on snapshot mina."
  	page.save_screenshot 'Create_site_with_snapshot.png'
  end

end
