require 'spec_helper'

describe "view_collections", :type => :request do

  it "should display view_collections", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    @collection = create_collection_for(@user)
    login_as (@user)
    visit "/?explicit=true"
    click_button ("View your collections")

    expect(page).to have_content ("Central Hospital")
  end
end