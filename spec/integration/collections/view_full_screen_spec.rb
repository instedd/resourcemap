require 'spec_helper'

describe "view_full_screen", :type => :request do

it "should change to full screen view", js:true do
    @user = User.make!(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user)
    login_as (@user)
    visit collections_path

    find(:xpath, '//div[@id="right-panel"]/div[1]/button[1]').click

    page.has_content?("icon_button right frestore")

    page.save_screenshot 'Full screen view.png'
  end
end