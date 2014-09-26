require 'spec_helper' 

describe "refine_results", :type => :request do 
 
  it "refine results", js:true do
    
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user) 
    login_as (@user)
    visit collections_path
    sleep 2
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    page.find(:xpath, '//div[@id="refine-container"]/div[1]/div').click
    page.find(:xpath, '//div[@class="refine-popup box"]/div[@id="div"][2]/span').click
    page.find(:xpath, '//div[@class="refine-popup box"]/div[@id="div"][2]/div[@id="div"]/a[@class="white button"]').click
    sleep 2
    expect(page).to have_content 'Show sites with location missing'
    sleep 2
    page.save_screenshot('Refine results.png')
  end
end


