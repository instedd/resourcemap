require 'spec_helper'

describe "create_layer", :type => :request do
  let(:user) do
    new_user
  end

  it "should create layer", js:true do
    create_collection_for user
    login_as user
    visit collections_path
    find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click
    click_link "Layers"
    click_button 'Add new layer'
    fill_in 'name', :with => 'Test'
    click_button 'Add new text field'
    fill_in 'field_name', :with => 'Test name'
    fill_in 'code', :with => 'Codigo'
    click_button 'Save layer'
    expect(page).to have_content "Layer 'Test' successfully saved"
  end
end
