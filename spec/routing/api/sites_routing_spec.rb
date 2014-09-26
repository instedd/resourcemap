require 'spec_helper'

describe "routes for Sites Api", :type => :routing do
  it "should route to show site" do
    expect(get("/api/sites/1.rss")).
      to route_to(
        controller: 'api/sites', 
        action: 'show', 
        id: '1',
        format: 'rss'
      )
  end
end
