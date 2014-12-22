require 'spec_helper'

describe "change_phone_number", :type => :request do
    let(:user){new_user}
    let(:collection){create_collection_for(user)}
    it "should change phone number", js:true, skip:true do
        login_as (user)
        visit collections_path
        sleep 2
        # find(:xpath, '//div[@id="User"]').click
        # click_link 'Settings'
        find(:xpath, '//div[@id="toolbar"]/ul[2]/li[2]/a').click
        within "form#edit_user" do
          fill_in "user_phone_number", :with => '1209348756'
        end
        click_button 'Update'
        sleep 1
        page.save_screenshot 'Change_phone_number.png'
        expect(page).to have_content 'Account updated successfully'
        find(:xpath, '//div[@id="toolbar"]/ul[2]/li[2]/a').click
        p 'Bug 549'
        expect(page).to have_content '1209348756'
    end
end
