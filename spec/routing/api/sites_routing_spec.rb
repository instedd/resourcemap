require 'spec_helper'

describe "routes for Sites Api" do
  it "should route to show site" do
    get("/api/sites/1").
      should route_to(
        controller: 'api/sites', 
        action: 'show', 
        id: '1',
        format: 'rss'
      )
  end
end
