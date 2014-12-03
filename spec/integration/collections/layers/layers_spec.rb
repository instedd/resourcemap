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

  it "should create layer", js:true do

    who_african_region.memberships.create! :user_id => user.id, :admin => true
    login_as (user)
    visit collections_path
    find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click
    click_link "Layers"
    click_button 'Add new layer'
    fill_in 'name', :with => 'Test'
    click_button 'Add new text field'
    fill_in 'field_name', :with => 'Test name'
    fill_in 'code', :with => 'Code'
    click_button 'Save layer'

    expect(page).to have_content "Saving layer, please wait..."
    expect(page).to have_content "Layer 'Test' successfully saved"

  end

end