require 'spec_helper'

describe "change_password", :type => :request do
  let(:user){new_user}
  let(:collection){create_collection_for(user)}

  it "should change password", js:true do
      login_as(user)
      visit collections_path
      sleep 2
      # find(:xpath, '//div[@id="User"]').click
      # click_link 'Settings'
      find(:xpath, '//div[@id="toolbar"]/ul[2]/li[2]/a').click
      within "form#edit_user" do
        fill_in "user_current_password", :with => user.password
        fill_in "user_password", :with => 'dexmor.15'
        fill_in "user_password_confirmation", :with => 'dexmor.15'
      end
      click_button 'Update'
      sleep 1
      page.save_screenshot 'Change_password.png'
      #Bug 511 (?)
      expect(page).to have_content 'You updated your account successfully'
  end

end
