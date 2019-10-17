require 'spec_helper'

describe "uncheck_events_activity", :type => :request do

  it "should uncheck events activity", js:true do
    @user = User.make(:email => 'user@manas.com.ar', :password => '1234567', :phone_number => '855123456789')
    collection = create_collection_for(@user)
    layer = create_layer_for (collection)
    field = create_field_for (layer)
    login_as (@user)
    visit collections_path
    click_link ('Activity')

    page.save_screenshot 'TabActivity.png'
    expect(page).to have_content ('Activity')
    find(:xpath, "//div[@class='tabsline']/table/tbody/tr[2]/td[2]/span[2]").click

    expect(page).to have_no_content ('mina@gutkowski.com')
    puts "\n\n\nScreen resolution is: #{Capybara.current_session.current_window.size}\n\n\n"
    page.save_screenshot 'Uncheck events_activity.png'
  end
end
