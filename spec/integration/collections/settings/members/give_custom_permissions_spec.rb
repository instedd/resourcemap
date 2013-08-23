require 'spec_helper' 

describe "members" do 
 
it "should manage custom permissions", js:true do
    admin = User.make(:email => 'admin@admin.com')
    collection = create_collection_for(admin) 
    10.times  do |i| 
        sites = create_site_for(collection, "Clinica-#{i}")
        end   
    user = User.make(:email => 'member@member.com')
    user.memberships.make collection: collection, admin: false
	login_as (admin)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    click_link "Members"
    page.find(:xpath, '//div[@class="memberHeaderRow"]/div[@class="memberHeaderColumn collapsed"]/span').click
    fill_in 'Add custom permissions for site', :with => 'Clinica-2'
    page.find('.clist-add').click
    choose('ko_unique_5')
    visit current_path
    page.find(:xpath, '//div[@class="memberHeaderRow"]/div[@class="memberHeaderColumn collapsed"]/span').click
    page.should have_content 'Clinica-2'
    page.save_screenshot 'Custom permissions'
    sleep 3
   end
end