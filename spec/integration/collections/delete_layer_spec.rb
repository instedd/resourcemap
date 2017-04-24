require 'spec_helper'

describe "delete_layer", :type => :request do

  pending "should delete layer", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    page.save_screenshot 'edit_layer.png'
    collection = create_collection_for(@user)
    layer = create_layer_for (collection)
    field = create_field_for (layer)
    login_as (@user)
    visit collections_path
    find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click
    click_link "Layers"
    click_button "Remove layer"
    confirm_popup

    expect(page).to have_content "Layer Central Hospital Layer 1 successfully deleted"
  end
end
