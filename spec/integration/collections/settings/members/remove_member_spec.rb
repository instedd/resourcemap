require 'spec_helper' 

describe "members" do 
 
it "should remove member", js:true do
    admin = User.make(:email => 'admin@admin.com')
    collection = create_collection_for(admin) 
    user = User.make(:email => 'member@member.com')
    user.memberships.make collection: collection, admin: false
    login_as (admin)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    click_link "Members"
    # find(:xpath, '//div[@id="container"]/div[2]/table/tbody/tr[3]/td/div/div[5]/input').click
    page.find(:xpath, '//div[@id="container"]/div[2]/table/tbody/tr[3]/td/div/div[1]/img').click
    page.find(:xpath, '//div[@class="memberHeaderColumn"]/a[@class="icon fdelete black"]').click
    page.find(:xpath, '//div[@class="sbox grey"]/div[3]/a[@class="button white right"]').click
    page.should have_no_content ('member@member.com')
    page.save_screenshot 'Remove_member.png'
    sleep 3
  end
end
