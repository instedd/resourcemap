require 'spec_helper'

describe "members", :type => :request, uses_collections_structure: true do
  let (:user) do
    new_user
  end

  before :each do
    who_african_region.memberships.create! :user_id => user.id, :admin => true
    login_as (user)
    visit collections_path
    find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click
  end

  it "should add collection reader", js:true do
    no_member = User.make(:email => 'member@member.com')
    click_link "Members"
    fill_in "member_email", :with => no_member.email
    click_on no_member_email

    expect(page).to have_content no_member.email

    find_by_id('User').click
    click_link 'Sign out'

    login_as (no_member)
    visit collections_path
    find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click

    expect(page).to have_content 'Leave collection'
  end

  it "should give admin rights", js:true do
    no_member = User.make(:email => 'member@member.com')
    click_link "Members"
    fill_in "member_email", :with => no_member.email
    click_on no_member_email

    expect(page).to have_content no_member.email

    check_admin_rights
    find_by_id('User').click
    click_link 'Sign out'

    login_as (no_member)
    visit collections_path
    find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click

    expect(page).to have_content 'Leave collection'
    expect(page).to have_content "Members"
  end

  it "should remove member", js:true do
    member = User.make(:email => 'member@member.com')
    who_african_region.memberships.create! :user_id => member.id, :admin => false
    click_link "Members"
    expand_member_settings
    find('.icon').click
    confirm_remove_member

    expect(page).to have_no_content ('member@member.com')
  end
end

describe "non-members", :type => :request, uses_collections_structure: true do
  let (:user) do
    new_user
  end

  before :each do
    who_african_region.memberships.create!
    login_as (user)
    visit collections_path
  end

  it "should not access to Collection settings if user do not have permission to access the collection", js:true, skip:true do
    access(who_african_region.id,"members")

    expect(page).not_to have_content 'Members'

    access(who_african_region.id,"settings")

    expect(page).not_to have_content 'Settings'

    access(who_african_region.id,"layers")

    expect(page).not_to have_content 'Layers'

    access(who_african_region.id,"import_wizard")

    expect(page).not_to have_content 'Import Wizard'
  end
end

