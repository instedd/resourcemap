require 'spec_helper' 

describe "edit_site", :type => :request do
  let(:user) do
    new_user
  end

  before(:each) do
    @collection = create_collection_for(user)
    @site = create_site_for(@collection, 'A Site')
    login_as user
    visit collections_path
  end

  it "edit site", js:true do
    click_on first_collection_path
    click_on first_site_path

    click_link 'Edit Site'
    fill_in 'locationText', :with => '-37.991902, -57.602087'
    click_button 'Done'
    expect(page).to have_no_content('26.7574, 14.3574')
    expect(page).to have_content('-37.991902, -57.602087')
  end

  it "should edit the site when navigating through a bookmarked URL", js: true do
    # edited site is loaded via AJAX
    visit collections_path(editing_site: @site.id, collection_id: @collection.id)

    expect(page).to have_content('Name: A Site')
    expect(page).to have_link('Edit Site')
    expect(page).to have_link('Delete Site')
  end

  it "should go to a site when clicking on the map marker", js: true do
    # NB: this is a bit brittle but I didn't find a better way of getting a
    # reference to a clickable marker; Google Maps creates marker that are not
    # easily identifiable from any HTML attribute
    page.all('#map img[src*=resmap_default]').last.click
    expect(page).to have_content('Name: A Site')
    expect(page).to have_link('Edit Site')
    expect(page).to have_link('Delete Site')
  end

  it "should not break when clicking a site marker a second time (#862)", js: true do
    page.all('#map img[src*=resmap_default]').last.click
    expect(page).to have_content(@site.name)
    click_on back_to_sites_button
    expect(page).to have_content(@collection.name)
    click_on back_to_collections_button
    expect(page).to have_content('My Collections')

    # navigate a second time through the marker
    page.all('#map img[src*=resmap_default]').last.click
    expect(page).to have_content(@site.name)
    click_on back_to_sites_button
    expect(page).to have_content(@collection.name)
    click_on back_to_collections_button
    expect(page).to have_content('My Collections')
  end
end
