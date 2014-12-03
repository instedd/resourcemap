require 'spec_helper'

describe "load_snapshot", :type => :request do

  it "should load a snapshot", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user)
    login_as (@user)
    visit collections_path
  	find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click
  	fill_in 'snapshot_name', :with => 'Snapshot2'
  	click_button 'Take new snapshot'
  	sleep 2
  	expect(page).to have_content 'Snapshot2'
  	choose ('name_Snapshot2')
    sleep 1
    page.save_screenshot "Load snapshot"
    expect(page).to have_content 'Snapshot Snapshot2 loaded'
  end
end
