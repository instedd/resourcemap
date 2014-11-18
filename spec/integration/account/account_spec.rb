require 'spec_helper'

describe "account", :type => :request, uses_collections_structure: true do
  let (:user) do
    new_user
  end

  before :each do
    visit collections_path
  end

  it "should login", js:true do
    who_african_region.memberships.create! :user_id => user.id
    visit collections_path
    click_link 'Log in'

    within login_form do
      fill_in  "Email", :with => user.email
      fill_in  "Password", :with => "1234567"
      click_button('Log In')
    end

    expect(find(notice_div)).to have_content('Signed in successfully')
    expect(page).to have_content('WHO African Region')
  end

  it " should not change password", js:true do

    login_as (user)
    visit collections_path
    find_by_id('User').click
    click_link 'Settings'

    within "form#edit_user" do
      fill_in "user_current_password", :with => user.password
      fill_in "user_password", :with => 'invalid'
      click_button 'Update'
    end

    expect(page).to have_content "Password confirmation doesn't match Password"

  end

  it " should log out", js:true do

    login_as (user)
    visit collections_path
    find_by_id('User').click
    click_link 'Sign out'

    expect(page).to have_content('Signed out successfully.')

  end

  it "should create an account", js:true do

    click_link 'Create account'
    page.has_content? "form#new_user"

    within login_form do
      fill_in  "Email", :with => 'user@manas.com.ar'
      fill_in  "Password", :with => "1234567"
      fill_in  "Password confirmation", :with => "1234567"
      fill_in  "Phone number", :with => "1234567"
      click_button ('Create account')
    end
    new_user = User.find_by_email('user@manas.com.ar')
    new_user.should_not be_nil
    new_user.confirmation_token.should_not be_nil
    expect(new_user.confirmed?).to be_falsey

    visit "/users/confirmation?#{get_confirmation_token()}"

    page.should have_content('Your account was successfully confirmed. You are now signed in.')
    new_user = User.find_by_email('user@manas.com.ar')
    expect(new_user.confirmed?).to be_truthy
  end

  it "should fail to login", js:true do

    click_link 'Log in'

    within login_form do
      fill_in  "Email", :with => user.email
      fill_in  "Password", :with => "Password01"
      click_button('Log In')
    end

    page.save_screenshot 'login_fail.png'
    expect(page).to have_content("Invalid email or password.")

  end

  it " should change phone number", js:true do

    login_as (user)
    visit collections_path
    find_by_id('User').click
    click_link 'Settings'

    within "form#edit_user" do
      fill_in "user_phone_number", :with => '12345'
      click_button 'Update'
    end

    expect(page).to have_content 'Account updated successfully'
    find_by_id('User').click
    click_link 'Settings'
    expect(page).to have_content "12345"

  end

  it " should change password", js:true do

    login_as (user)
    visit collections_path
    find_by_id('User').click
    click_link('Settings')

    within "form#edit_user" do
      fill_in "user_password", :with => "Password01"
      fill_in "user_password_confirmation", :with => "Password01"
      fill_in "user_current_password", :with => user.password
      click_button('Update')
    end

    expect(find(notice_div)).to have_content('You updated your account successfully.')

    find_by_id('User').click
    click_link('Sign out')

    user.reload

    click_link 'Log in'

    within login_form do
      fill_in  "Email", :with => user.email
      fill_in  "Password", :with => "Password01"
      click_button('Log In')
    end

    page.should have_content(user.email)

  end

end

