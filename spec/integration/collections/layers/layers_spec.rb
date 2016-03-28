require 'spec_helper'

describe "layer", :type => :request, uses_collections_structure: true do
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

  it "should import layer", js:true do
    visit collections_path
    click_on create_collection_link
    fill_in  "collection_name", :with => 'Test Collection'
    click_button "Save"
    click_link "Layers"
    expand_advanced_options

    click_button 'Import'

    expect(page).to have_content 'Imported layers from WHO African Region'
   	expect(page).to have_content "WHO African Region layer"
  end

  it "should create layer", js:true do
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

  it "should delete layer", js:true do
    click_link "Layers"

    click_button "Remove layer"
    confirm_popup

    expect(page).to have_content "Layer WHO African Region layer successfully deleted"
  end

  it "should edit layer", js:true do
    click_link "Layers"

    click_button "Edit"
    fill_in 'Name', :with => 'Test Layer'
    click_button 'Save layer'

    expect(page).to have_content "Layer 'Test Layer' successfully saved"
  end

  it "should sort layer", js:true do
    lay = who_african_region.layers.make(:name => 'layer2')
    lay.text_fields.make

    click_link "Layers"
    click_button "Move layer down"
    click_on edit_layer_button

    expect(page).to have_content 'layer2'
  end

end
