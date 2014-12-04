require 'spec_helper'

describe "collection", :type => :request, uses_collections_structure: true do
  let (:user) do
    new_user
  end

  before :each do
    who_african_region.memberships.create! :user_id => user.id, :admin => true
    login_as (user)
    visit collections_path
    find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click
  end

  it "should create collection", js:true do

    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[3]/button').click
    fill_in  "collection_name", :with => 'My collection'
    click_button "Save"

    expect(find(notice_div)).to have_content('Collection My collection created')

    visit collections_path

    expect(page).to have_content('My collection')
  end

  it "should change a collection name", js:true do

    click_link "Settings"
    fill_in  "collection_name", :with => 'New Colection Name'
    click_button "Save"
    expect(page).to have_content "Collection New Colection Name updated"

  end

  it " should change a collections icon", js:true do

    click_link "Settings"
    page.find(".army").click
    click_button "Save"

    expect(page).to have_content "Collection Central Hospital updated"
  end

  it "should clear search", js:true do

    visit collections_path
    find(:xpath, first_collection_path).click
    fill_in 'search', :with => "Kenya\n"

    expect(page).to have_content 'Kenya'
    click_link 'clear search'

    expect(page).to have_content 'Rwanda'

  end

  it "should delete a collection", js:true do

    click_link "Delete collection"
    click_link "Confirm"

    expect(page).to have_content "Collection Central Hospital deleted"

  end

  it "should change to collection via breadcrumb", js:true do

    click_link "Settings"
    page.find(:xpath, '//div[@class="BreadCrumb"]/ul/li[1]/a').click

    expect(page).to have_content "My Collections"
    expect(page).to have_content "Create Collection"
  end

end

