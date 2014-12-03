require 'spec_helper'

describe "layer", :type => :request, uses_collections_structure: true do
  let (:user) do
    new_user
  end

  before :each do
    visit collections_path
  end

  it "should import layer", js:true do

    who_african_region.memberships.create! :user_id => user.id, :admin => true
    login_as (user)
    visit collections_path
    page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[3]/button').click
    fill_in  "collection_name", :with => 'Test Collection'
    click_button "Save"
    click_link "Layers"
    page.find(:xpath, '//div[@class="tabsline"]/div[@id="layers-main"]/div[2]/img').click
    click_button 'Import'

    expect(page).to have_content 'Imported layers from WHO African Region'
   	expect(page).to have_content "WHO African Region layer"

  end

end