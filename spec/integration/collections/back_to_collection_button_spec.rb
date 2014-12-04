require 'spec_helper'

describe "back_to_colletion_button", :type => :request do

  it "should go back to collection", js:true do
    user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    page.save_screenshot 'create_collection.png'
    collection = create_collection_for (user)
    create_site_for (collection)
    login_as (user)
    visit collections_path
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click

    find('.pback').click

    expect(page).to have_content ("Central Hospital")
    expect(page).to have_content ("My Collections")
  end
end
