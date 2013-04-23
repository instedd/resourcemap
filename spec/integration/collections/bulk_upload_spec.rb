require 'spec_helper' 

describe "bulk_upload" do 
 
  it "should upload a bulk for a collection", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user) 
    login_as (@user)
    visit collections_path
  	page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
  	page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
	click_link "Upload it for bulk sites updates"
  	sleep 3
  	page.has_content? ('#upload')
  	page.attach_file 'upload', 'Pesca_sites.csv'
  	click_button "Start importing"
  	sleep 6
  	page.save_screenshot ("Upload a bulk.png")
  	page.should have_content "Lago Fagnano"
  end
end