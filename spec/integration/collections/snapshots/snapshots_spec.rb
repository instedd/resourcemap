require 'spec_helper'

describe "snapshots", :type => :request, uses_collections_structure: true do
  let (:user) do
    new_user
  end

  before :each do
    who_african_region.memberships.create! :user_id => user.id, :admin => true
    login_as (user)
    visit collections_path
  end

  it "should load a snapshot", js:true do

    find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click
    fill_in 'snapshot_name', :with => 'Snapshot2'
    click_button 'Take new snapshot'
    expect(page).to have_content 'Snapshot2'
    choose ('name_Snapshot2')
    page.save_screenshot "Load snapshot"
    expect(page).to have_content 'Snapshot Snapshot2 loaded'

  end

end