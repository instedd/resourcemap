require 'spec_helper'

describe "collection", :type => :request, uses_collections_structure: true do
  let (:user) do
    new_user
  end

  before :each do
    visit collections_path
  end

  it "should create collection", js:true do
    login_as (user)
    visit collections_path

    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[3]/button').click
    sleep 1
    fill_in  "collection_name", :with => 'My collection'
    click_button "Save"

    expect(find(notice_div)).to have_content('Collection My collection created')

    visit collections_path

    expect(page).to have_content('My collection')
  end

end

