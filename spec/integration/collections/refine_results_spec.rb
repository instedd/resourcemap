require 'spec_helper'

describe "refine_results", :type => :request do

  let(:user) do
    new_user
  end

  it "refine results", js: true do
    create_collection_for(user)
    login_as user
    visit collections_path

    click_on first_collection_path
    page.find('.refine').click
    page.find('span', text: 'Location missing').click
    page.find('a', text: 'OK').click

    expect(page).to have_content 'sites with location missing'
  end
end


