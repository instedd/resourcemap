require 'spec_helper'

describe "routes for Api Collections" do
  it "should route to show collection" do
    get("/api/collections/1").
      should route_to(
        controller: 'api/collections', 
        action: 'show', 
        id: '1' 
      )
  end
end
