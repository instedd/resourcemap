require 'spec_helper'

describe "read_json", :type => :request do

  it "should read json", js:true do
    admin = User.make(:email => 'admin@admin.com')
    collection = create_collection_for(admin)
    10.times  do |i|
        sites = create_site_for(collection, "Clinica-#{i}")
        end
    login_as (admin)
    visit collections_path
    find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click
    click_link('JSON')

    new_window=page.driver.browser.window_handles.last

    page.within_window new_window do
        # page.title.should eq collection.name
        expect(page.current_url).to include("/api/collections/#{collection.id}.json")
        page.save_screenshot 'Json.png'
    end
  end
end