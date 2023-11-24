require 'spec_helper'

describe "delete_collection_sites", :type => :request do

  it "should delete sites of a collection", js:true do
    @user = User.make!(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user)
    login_as (@user)
    visit collections_path
  	find(:xpath, first_collection_path).click
  	find("#collections-main").find("button.fconfiguration").click
  	click_link "Delete this collection's sites"
  	click_link "Confirm"

  	page.save_screenshot "Delete Collection Sites.png"

  	expect(page).to have_content "Collection Central Hospital's sites deleted"
  end
end