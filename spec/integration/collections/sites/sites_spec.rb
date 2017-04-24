require 'spec_helper'

describe "sites", :type => :request, uses_collections_structure: true do
  let(:user) do
    new_user
  end

  before :each do
    who_african_region.memberships.create! :user_id => user.id, :admin => true
    login_as user
    visit collections_path
    click_on first_collection_path
  end

  it "should create a site", js:true do
    click_button 'Create Site'
    fill_in 'name', :with => 'New site'
    fill_in 'locationText', :with => '-37.991902, -57.602087'
    click_button 'Done'

    expect(find(notice_div)).to have_content("Site 'New site' successfully created")
    site_row = find('.sites tr', text: 'New site')
    site_row.find('.farrow').click
    expect(page).to have_content(/Name:\s*New site/)
    click_link 'Edit Site'
  end

  it "should show validation errors", js: true do
    click_button 'Create Site'
    click_button 'Done'

    expect(page).to have_selector('.error')
    expect(page).to have_content('site cannot be saved due to validation errors')
  end

  pending "should filter sites by name", js:true do
    find('.refine').click
    click_on expand_name
    fill_starts_with("Ken")
    find('.button').click

    expect(page).to have_content "where Name starts with 'Ken' "
    expect(page).to have_content 'Kenya'
    expect(page).to have_no_content 'Rwanda'
  end
end
