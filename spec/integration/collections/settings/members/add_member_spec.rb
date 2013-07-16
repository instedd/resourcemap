require 'spec_helper' 

describe "members" do 
 
it "should add member", js:true do
    admin = User.make(:email => 'admin@admin.com')
    collection = create_collection_for(admin) 
    user = User.make(:email => 'member@member.com')
    # user.memberships.make collection: collection, admin: false
    login_as (admin)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    click_link "Members"
    fill_in "member_email", :with => "member@member.com"
    page.find(:xpath, '//div[@id="autocomplete_container"]/ul/li/a').click
    sleep 3
    page.should have_content 'member@member.com'
    page.save_screenshot 'Add member.png'
  end
end
