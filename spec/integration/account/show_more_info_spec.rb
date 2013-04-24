require 'spec_helper' 

describe "show_more_info" do 
 
  it "should show user more info", js:true do
 	visit "/"
 	sleep 1
 	click_link "Find out how"
 	sleep 1
 	page.save_screenshot 'Show_more_info.png'
 	page.should have_content "How does it work?"
  end
end