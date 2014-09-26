require 'spec_helper' 

describe "navigate_breadcrumb", :type => :request do 
 
it "should change to collection via breadcrumb", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user) 
    login_as (@user)
    visit collections_path
    sleep 2
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    click_link "Settings"
    sleep 3
    page.find(:xpath, '//div[@class="BreadCrumb"]/ul/li[1]/a').click
    sleep 2
  	page.save_screenshot "Navigate breadcrumb.png"
  	expect(page).to have_content "My Collections"
    expect(page).to have_content "Create Collection"
  end
end