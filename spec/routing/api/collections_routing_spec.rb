require 'spec_helper'

describe "routes for Api Collections", :type => :routing do
  it "should route to show collection" do
    expect(get("/api/collections/1.rss")).
      to route_to(
        controller: 'api/collections', 
        action: 'show', 
        id: '1',
        format: 'rss'
      )
  end
end
