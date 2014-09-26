require 'spec_helper' 

describe "navigate_carrousel", :type => :request do 
 
  it "should navigate carrousel", js:true do
 	visit "/"
 	sleep 1
 	find(:xpath, '//div[@id="container"]/div/div[3]/div/div/div[3]/a').click
 	expect(page).to have_content 'Maintain'
 	find(:xpath, '//div[@id="container"]/div/div[3]/div/div/div[3]/a').click
 	expect(page).to have_content 'Open Source'
 	page.save_screenshot 'navigate_carrousel.png'
  end
end