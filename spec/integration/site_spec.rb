require 'spec_helper'

describe "change field values", :type => :request, uses_collections_structure: true do
  let (:user) do
    new_user
  end

  it "", js:true do
    multicollection.memberships.create! :user_id => user.id, :admin => true
    s = multicollection.sites.make name: "Third Site", id: 3
    login_as(user)
    visit collections_path
    find(:xpath, first_collection_path).click
    find(:xpath, first_site_path).click

    date_escode = multicollection_date_field.es_code
    identifier_escode = multicollection_identifier_field.es_code

    click_link 'Edit Site'

    expect(find('#numeric-input-numeric').value).to eq('987654321')
    expect(find('#text-input-text').value).to eq('before_changed')
    old_value_for_select_one = label_for_id(multicollection_select_one_field, '1')
    expect(page).to have_content(old_value_for_select_one)
    expect(find('#select-one-input-selone').value).to eq('1')
    expect(find("#date-input-#{date_escode}").value).to eq("12/15/2013")
    expect(find('#email-input-email').value).to eq("before@manas.com.ar")
    expect(find("#identifier-input-#{identifier_escode}").value).to eq('42')
    expect(find('#phone-input-phone').value).to eq("4444")
    expect(find('#site-input-site').value).to eq("Second Site")
    expect(find('#user-input-user').value).to eq("user2@manas.com.ar")

    fill_in 'numeric-input-numeric', :with => '1234567890'
    fill_in 'text-input-text', :with => 'after_changed'
    new_value_for_select_one = label_for_id(multicollection_select_one_field, '2')
    select(new_value_for_select_one, :from => 'select-one-input-selone')
    fill_in "date-input-#{date_escode}", :with => "12/15/2015"
    fill_in "email-input-email", :with => "after@manas.com.ar"
    fill_in "identifier-input-#{identifier_escode}", :with => 360
    fill_in "phone-input-phone", :with => 55555
    fill_in "site-input-site", :with => "Third Site"
    fill_in "user-input-user", :with => user.email
    page.uncheck('yes-no-input-yes_no')
    click_button 'Done'

    click_link 'Edit Site'

    expect(find('#numeric-input-numeric').value).to eq('1234567890')
    expect(find('#text-input-text').value).to eq('after_changed')
    expect(find('#select-one-input-selone').value).to eq('2')
    expect(page).to have_content(new_value_for_select_one)
    expect(find("#date-input-#{date_escode}").value).to eq("12/15/2015")
    expect(find('#email-input-email').value).to eq("after@manas.com.ar")
    expect(find("#identifier-input-#{identifier_escode}").value).to eq("360")
    expect(find('#phone-input-phone').value).to eq("55555")
    expect(find('#site-input-site').value).to eq("Third Site")
    expect(find('#user-input-user').value).to eq(user.email)
  end
end
