require 'spec_helper'

describe "routes for Memberships", :type => :routing do
  it "should route to search" do
    expect(get("/collections/1/memberships/search")).
      to route_to(
        controller: 'memberships', 
        action: 'search', 
        collection_id: '1'
      )
  end
end
