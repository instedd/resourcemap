require 'spec_helper'

describe "import_wizard", :type => :request, uses_collections_structure: true do
  let (:user) do
    new_user
  end

  it "should import a site", js:true, uses_collections_structure: true do

    date_escode = multicollection_date_field.es_code
    identifier_escode = multicollection_identifier_field.es_code
    new_value_for_select_one = label_for_id(multicollection_select_one_field, '2')
    multicollection.memberships.create! :user_id => user.id, :admin => true
    login_as (user)
    visit collections_path
    find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click
    click_link "Upload it for bulk sites updates"
    attach_file("upload","multicollection_site.csv")

    with_resque do
        click_button "Start importing"
        sleep 3
    end
    click_button "Browse collection"

    find(:xpath, first_site_path).click
    click_link 'Edit Site'

    expect(find('#numeric-input-numeric').value).to eq('1234567890')
    expect(find('#text-input-text').value).to eq('after_changed')
    expect(find('#select-one-input-selone').value).to eq('2')
    expect(page).to have_content(new_value_for_select_one)
    expect(find("#date-input-#{date_escode}").value).to eq("12/15/2015")
    expect(find('#email-input-email').value).to eq("after@manas.com.ar")
    expect(find("#identifier-input-#{identifier_escode}").value).to eq("360")
    expect(find('#phone-input-phone').value).to eq("55555")
    expect(find('#site-input-site').value).to eq("Second Site")
    expect(find('#user-input-user').value).to eq(user.email)

  end

  it "should NOT upload a bulk for a collection", js:true, uses_collections_structure: true do

    who_african_region.memberships.create! :user_id => user.id, :admin => true
    login_as (user)
    visit collections_path
    find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click
    click_link "Upload it for bulk sites updates"
    page.has_content? ('#upload')
    page.attach_file 'upload', 'sanitized_rwanda_schema.json'

    expect(page).to have_content ('Invalid file format. Only CSV files are allowed.')

  end

  it "should cancel import", js:true, uses_collections_structure: true do

    multicollection.memberships.create! :user_id => user.id, :admin => true
    login_as (user)
    visit collections_path
    find(:xpath, first_collection_path).click
    find("#collections-main").find("button.fconfiguration").click
    click_link "Upload it for bulk sites updates"
    attach_file("upload","multicollection_site.csv")
    click_button "Start importing"
    click_button "Cancel import"

    expect(page).to have_content "Import canceled"

  end

end

