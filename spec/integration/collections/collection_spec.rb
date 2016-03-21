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
    click_on create_collection_link

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

    find(".army").click
    click_button "Save"

    expect(page).to have_content "Collection WHO African Region updated"
  end

  it "should clear search", js:true, skip:true do
    visit collections_path
    click_on first_collection_path

    fill_in 'search', :with => "Kenya\n"

    expect(page).to have_content 'Kenya'

    sleep 1
    click_link 'clear search'

    expect(page).to have_content 'Rwanda'
  end

  it "should delete a collection", js:true do
    click_link "Delete collection"
    click_link "Confirm"

    expect(page).to have_content "Collection WHO African Region deleted"
  end

  it "should change to collection via breadcrumb", js:true do
    click_link "Settings"

    click_on breadcrumb_collection_link

    expect(page).to have_content "My Collections"
    expect(page).to have_content "Create Collection"
  end

  it "should export collection sites as RSS", js: true do
    rss_window = window_opened_by { click_link('RSS') }

    within_window rss_window do
      # TODO: these are driver/browser specific and don't work in all cases;
      # find a better way to test that the content was correctly loaded
      # expect(page.title).to eq(who_african_region.name)
      # expect(page).to have_content who_african_region.name
      expect(page.current_url).to include("/api/collections/#{who_african_region.id}.rss")
    end

    rss_window.close
  end

  it "should export collection sites as json", js: true do
    json_window = window_opened_by { click_link('JSON') }

    within_window json_window do
      expect(page).to have_content who_african_region.name
      expect(page.current_url).to include("/api/collections/#{who_african_region.id}.json")
    end

    json_window.close
  end
end
