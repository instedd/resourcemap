require 'spec_helper'

describe "navigate_map", :type => :request do

  it "should navigate map", js:true, skip:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user)
    login_as (@user)
    visit collections_path
    find(:xpath, '//div/div[@class="gmnoprint"][3]/div[@class="gmnoprint"][1]/div[@class="gmnoprint"][2]/div/div[2]').click
    sleep 1
    find(:xpath, '//div/div[@class="gmnoprint"][3]/div[@class="gmnoprint"][1]/div[@class="gmnoprint"][2]/div/div[2]').click
 	sleep 1
    find(:xpath, '//div/div[@class="gmnoprint"][3]/div[@class="gmnoprint"][1]/div[@class="gmnoprint"][2]/div/div[2]').click
    sleep 1
	find(:xpath, '//div/div[@class="gmnoprint"][3]/div[@class="gmnoprint"][1]/div[@class="gmnoprint"][2]/div/div[3]').click
	sleep 1
	find(:xpath, '//div/div[@class="gmnoprint"][3]/div[@class="gmnoprint"][1]/div[@class="gmnoprint"][2]/div/div[3]').click
	sleep 1
	find(:xpath, '//div/div[@class="gmnoprint"][3]/div[@class="gmnoprint"][1]/div[@class="gmnoprint"][2]/div/div[3]').click
	sleep 1
	find(:xpath, '//div/div[@class="gmnoprint"][3]/div[@class="gmnoprint"][1]/div[@class="gmnoprint"][2]/div/div[1]').click
	sleep 1
	find(:xpath, '//div/div[@class="gmnoprint"][3]/div[@class="gmnoprint"][1]/div[@class="gmnoprint"][2]/div/div[1]').click
	sleep 1
	find(:xpath, '//div/div[@class="gmnoprint"][3]/div[@class="gmnoprint"][1]/div[@class="gmnoprint"][2]/div/div[1]').click
	sleep 1
	find(:xpath, '//div/div[@class="gmnoprint"][3]/div[@class="gmnoprint"][1]/div[@class="gmnoprint"][2]/div/div[4]').click
	sleep 1
	find(:xpath, '//div/div[@class="gmnoprint"][3]/div[@class="gmnoprint"][1]/div[@class="gmnoprint"][2]/div/div[4]').click
	sleep 1
	find(:xpath, '//div/div[@class="gmnoprint"][3]/div[@class="gmnoprint"][1]/div[@class="gmnoprint"][2]/div/div[4]').click
	sleep 2
  end
end