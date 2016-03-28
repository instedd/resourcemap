require 'spec_helper'

describe "change_phone_number", :type => :request do
  let(:user) {
    new_user
  }

  it "should change phone number", js:true do
    login_as user
    visit root_path
    find_by_id('User').click
    click_link('Settings')
    within "form#edit_user" do
      fill_in "user_phone_number", :with => '1209348756'
    end
    click_button 'Update'
    expect(page).to have_content 'Account updated successfully'
    find_by_id('User').click
    click_link('Settings')
    expect(page).to have_field('user_phone_number', with: '1209348756')
  end
end
