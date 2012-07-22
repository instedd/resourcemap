require 'spec_helper'

describe "routes for Memberships" do
  it "should route to search" do
    get("/collections/1/memberships/search").
      should route_to(
        controller: 'memberships', 
        action: 'search', 
        collection_id: '1'
      )
  end
end
