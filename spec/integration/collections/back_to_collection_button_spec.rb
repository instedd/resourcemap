require 'spec_helper'

describe "back_to_colletion_button", :type => :request do

  let(:user) do
    new_user
  end

  it "should go back to collection", js: true do
    collection = create_collection_for(user)
    create_site_for collection
    login_as user
    visit collections_path
    click_on first_collection_path

    find('.pback').click

    expect(page).to have_content("Central Hospital")
    expect(page).to have_content("My Collections")
  end
end
