require 'spec_helper'

describe "unload_snapshot", :type => :request do

  pending "should go back to present time", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user)
    login_as (@user)
    visit collections_path
    find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click
    fill_in 'snapshot_name', :with => 'Snapshot3'
    click_button 'Take new snapshot'

    expect(page).to have_content 'Snapshot3'
    choose 'Snapshot3'

    expect(page).to have_content 'Snapshot Snapshot3 loaded'
    choose 'Present time'

    expect(page).to have_content ('Snapshot Snapshot3 unloaded')
  end
end
