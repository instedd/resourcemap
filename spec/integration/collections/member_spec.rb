require 'spec_helper'

describe "member", :type => :request, uses_collections_structure: true do
  let (:user) do
    new_user
  end

  it "should add collection reader", js:true do

      admin = User.make(:email => 'admin@admin.com')
      collection = create_collection_for(admin)
      user = User.make(:email => 'member@member.com')

      login_as (admin)
      visit collections_path
      page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
      find("#collections-main").find("button.fconfiguration").click
      click_link "Members"
      fill_in "member_email", :with => user.email
      page.find(:xpath, '//div[@id="autocomplete_container"]/ul/li/a').click
      expect(page).to have_content 'member@member.com'
      find_by_id('User').click
      click_link 'Sign out'

      login_as (user)
      visit collections_path
      page.find(:xpath, '//div[@id="collections-main"]/div[1]/div[2]/table/tbody/tr[1]/td/button').click
      find("#collections-main").find("button.fconfiguration").click

  end

end

