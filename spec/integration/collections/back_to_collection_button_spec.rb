require 'spec_helper' 

describe "delete_site" do 
 
  it "should delete site", js:true do
    user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    page.save_screenshot 'create_collection.png'
    collection = create_collection_for (user)
    create_site_for (collection)
    login_as (user)
    visit collections_path
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    sleep 5
    find('.pback').click
    sleep 2
    page.should have_content ("Central Hospital")
    page.should have_content ("My Collections")
  end
end
