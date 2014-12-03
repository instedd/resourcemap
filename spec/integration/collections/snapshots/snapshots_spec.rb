require 'spec_helper'

describe "snapshots", :type => :request, uses_collections_structure: true do
  let (:user) do
    new_user
  end

  before :each do
    my_snapshot= Snapshot.make :collection => who_african_region, :name => 'Snapshot1'
    UserSnapshot.make :user => user, :snapshot => my_snapshot
    who_african_region.memberships.create! :user_id => user.id, :admin => true
    login_as (user)
    visit collections_path
    find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click
  end

  it "should load a snapshot", js:true do

    fill_in 'snapshot_name', :with => 'Snapshot2'
    click_button 'Take new snapshot'
    expect(page).to have_content 'Snapshot2'
    choose ('name_Snapshot2')
    expect(page).to have_content 'Snapshot Snapshot2 loaded'

  end

  it "should not create site using snapshot", js:true do

    choose 'Snapshot1'
    visit collections_path
    find(:xpath, first_collection_path).click

    expect(page).not_to have_content "Create Site"
    expect(page).to have_content "You are currently viewing this collection's data as it was on snapshot Snapshot1."

  end

  it "should not edit layer with snapshot", js:true do

    choose 'Snapshot1'
    click_link "Layers"
    expect(page).not_to have_content "Edit"
    expect(page).to have_content "You are currently viewing this collection's data as it was on snapshot Snapshot1. To make changes, please"

  end

  it "should not edit site using snapshot", js:true do

    choose 'Snapshot1'
    visit collections_path
    find(:xpath, first_collection_path).click
    expect(page).not_to have_content "Kenya"
    page.has_content? "You are currently viewing this collection's data as it was on snapshot Snapshot1."

  end

end