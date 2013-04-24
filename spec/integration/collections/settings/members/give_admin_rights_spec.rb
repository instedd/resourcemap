require 'spec_helper' 

describe "members" do 
 
it "should give admin rights", js:true do
    admin = User.make(:email => 'admin@admin.com')
    collection = create_collection_for(admin) 
    user = User.make(:email => 'member@member.com')
    user.memberships.make collection: collection, admin: false
    login_as (user)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    page.should_not have_content "Members"
    find_by_id('User').click
    click_link('Sign Out')
    sleep 3
    login_as (admin)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    click_link "Members"
    find(:xpath, '//div[@id="container"]/div[2]/table/tbody/tr[3]/td/div/div[5]/input').click
    find_by_id('User').click
    click_link('Sign Out')
    sleep 3
    login_as (user)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    sleep 2
    page.save_screenshot 'Members.png'
    page.should have_content "Members"
  end
end
