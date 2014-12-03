require 'spec_helper'

describe "sites", :type => :request, uses_collections_structure: true do
  let (:user) do
    new_user
  end

  before :each do
    who_african_region.memberships.create! :user_id => user.id, :admin => true
    login_as (user)
    visit collections_path
    find(:xpath, first_collection_path).click
  end

end