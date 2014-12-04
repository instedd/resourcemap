require 'spec_helper'

describe "collection", :type => :request, uses_collections_structure: true do
  let (:user) do
    new_user
  end

  before :each do
    who_african_region.memberships.create! :user_id => user.id, :admin => true
    login_as (user)
    visit collections_path
  end

  it "should create collection", js:true do

    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[3]/button').click
    fill_in  "collection_name", :with => 'My collection'
    click_button "Save"

    expect(find(notice_div)).to have_content('Collection My collection created')

    visit collections_path

    expect(page).to have_content('My collection')
  end

  it "should change a collection name", js:true do

    find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click
    click_link "Settings"
    fill_in  "collection_name", :with => 'New Colection Name'
    click_button "Save"
    expect(page).to have_content "Collection New Colection Name updated"

  end

end

