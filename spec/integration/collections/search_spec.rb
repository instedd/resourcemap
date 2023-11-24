require 'spec_helper'

describe "search", :type => :request do
  let(:user) do
    new_user
  end

  pending "should search", js: true do
    collection = create_collection_for(user)
    layer = create_layer_for(collection)
    field = create_field_for(layer)
    10.times { collection.sites.make! properties: { field.es_code => 'fra' } }
    10.times { collection.sites.make! properties: { field.es_code => 'ter' } }
    collection.sites.make! name: 'Site search test'
    10.times { collection.sites.make! properties: { field.es_code => 'nity' } }
    login_as user
    visit collections_path
    click_on first_collection_path
    fill_in 'search', :with => "search test\n"

    expect(page).to have_content('clear search')
    expect(page).to have_content('Site search test')
    expect(page.find_all('.sites tr').count).to be(1)
  end
end


