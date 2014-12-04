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

  it "should create a site", js:true do

    find_button("Create Site").click
    fill_in 'name', :with => 'New site'
    fill_in 'locationText', :with => '-37.991902, -57.602087'
    click_button 'Done'

    expect(find(notice_div)).to have_content("Site 'New site' successfully created")

    find(:xpath, first_collection_path).click
    click_link 'Edit Site'

  end

  it "should filter sites by name", js:true do

    find('.refine').click
    find(:xpath, '//div[@class="refine-popup box"]/div[3]').click
    find(:xpath, '//div[@class="refine-popup box"]/div[4]/input').set("Ken")
    find(:xpath, '//div[@class="refine-popup box"]/div[4]/a').click
    expect(page).to have_content 'where Name starts with "Ken" '
    expect(page).to have_content 'Kenya'
    expect(page).not_to have_content 'Rwanda'

  end

end