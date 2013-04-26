require 'spec_helper' 

describe "zoom in and out" do 
 
  it "should zoom in and out", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for(@user) 
    create_site_for (collection)
    login_as (@user)
    visit collections_path
    find(:xpath, "//div[@id='map']/div/div[@class='gmnoprint'][3]/div[@class='gmnoprint'][3]/div[4]/img").click
    find(:xpath, "//div[@id='map']/div/div[@class='gmnoprint'][3]/div[@class='gmnoprint'][3]/div[4]/img").click
    find(:xpath, "//div[@id='map']/div/div[@class='gmnoprint'][3]/div[@class='gmnoprint'][3]/div[4]/img").click
    find(:xpath, "//div[@id='map']/div/div[@class='gmnoprint'][3]/div[@class='gmnoprint'][3]/div[4]/img").click
    find(:xpath, "//div[@id='map']/div/div[@class='gmnoprint'][3]/div[@class='gmnoprint'][3]/div[4]/img").click
    find(:xpath, "//div[@id='map']/div/div[@class='gmnoprint'][3]/div[@class='gmnoprint'][3]/div[4]/img").click
    find(:xpath, "//div[@id='map']/div/div[@class='gmnoprint'][3]/div[@class='gmnoprint'][3]/div[1]/img").click
    find(:xpath, "//div[@id='map']/div/div[@class='gmnoprint'][3]/div[@class='gmnoprint'][3]/div[1]/img").click
    find(:xpath, "//div[@id='map']/div/div[@class='gmnoprint'][3]/div[@class='gmnoprint'][3]/div[1]/img").click
    find(:xpath, "//div[@id='map']/div/div[@class='gmnoprint'][3]/div[@class='gmnoprint'][3]/div[1]/img").click
    find(:xpath, "//div[@id='map']/div/div[@class='gmnoprint'][3]/div[@class='gmnoprint'][3]/div[1]/img").click
  end
end
