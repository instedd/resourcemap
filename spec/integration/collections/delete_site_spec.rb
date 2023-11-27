require 'spec_helper'

describe "delete_site", :type => :request do

  it "should delete site", js:true do
    user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    page.save_screenshot 'create_collection.png'
    collection = create_collection_for (user)
    create_site_for (collection)
    login_as (user)
    visit collections_path
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
    find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click

    click_link 'Delete Site'

    page.driver.browser.switch_to.alert.accept

    page.save_screenshot "Delete_site.png"
    expect(page).to have_no_content ("Health Center")
  end
end

