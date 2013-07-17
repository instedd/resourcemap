require 'spec_helper' 

describe "bulk_upload_fail" do 
 
  it "should NOT upload a bulk for a collection", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user) 
    login_as (@user)
    visit collections_path
  	page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    sleep 2
  	page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[1]/button[2]').click
	  sleep 2
    click_link "Upload it for bulk sites updates"
  	sleep 2
  	page.has_content? ('#upload')
  	page.attach_file 'upload', 'sanitized_rwanda_schema.json'
    page.should have_content ('Invalid file format. Only CSV files are allowed.')
    sleep 2
    page.save_screenshot ("Upload bulk fail.png")
  end
end