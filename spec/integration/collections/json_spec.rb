require 'spec_helper' 

describe "read_json", :type => :request do 
 
  it "should read json", js:true do
    admin = User.make(:email => 'admin@admin.com')
    collection = create_collection_for(admin) 
    10.times  do |i| 
        sites = create_site_for(collection, "Clinica-#{i}")
        end  
    login_as (admin)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
    click_link('JSON')
    sleep 3
    new_window=page.driver.browser.window_handles.last 
    sleep 2
    page.within_window new_window do
        # page.title.should eq collection.name 
        expect(page.current_url).to include("/api/collections/#{collection.id}.json")
        page.save_screenshot 'Json.png'
    end
  end
end