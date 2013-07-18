require 'spec_helper' 

describe "add_custom_permissions" do 
 
  it "should add custom permissions", js:true do
    admin = User.make(:email => 'admin@admin.com')
    collection = create_collection_for(admin) 
    10.times  do |i| 
        sites = create_site_for(collection, "Clinica-#{i}") 
    end
    user = User.make(:email => 'member@member.com')
    user.memberships.make collection: collection, admin: true
    login_as (admin)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    sleep 2
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    click_link "Members"
    page.find(:xpath, '//div[@id="container"]/div[2]/table/tbody/tr[3]/td/div/div[1]/img').click
    fill_in 'Add custom permissions for site', :with => 'Clinica-2'
    page.find(:xpath, '//html/body/ul/li[1]/a').click
    page.find(:xpath, '//div[@class="frame"]/button[@class="clist-add"]').click
    sleep 3
    page.should have_content 'Custom permissions for 1 site'
    page.should have_content 'Clinica-2'
    page.save_screenshot 'Add permissions.png'
  end
end
