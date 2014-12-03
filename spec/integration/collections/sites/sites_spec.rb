require 'spec_helper'

describe "sites", :type => :request, uses_collections_structure: true do
  let (:user) do
    new_user
  end

  before :each do
    who_african_region.memberships.create! :user_id => user.id, :admin => true
    login_as (user)
    visit collections_path
    find(:xpath, first_collection_path).click
  end

  it "should not create site using snapshot", js:true do

    my_snapshot= Snapshot.make :collection => who_african_region, :name => 'Snapshot1'
    UserSnapshot.make :user => user, :snapshot => my_snapshot
    find("#collections-main").find("button.fconfiguration").click
    choose 'Snapshot1'
    visit collections_path
    find(:xpath, first_collection_path).click

    expect(page).not_to have_content "Create Site"
    expect(page).to have_content "You are currently viewing this collection's data as it was on snapshot Snapshot1."

  end

end