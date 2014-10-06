require 'spec_helper'

describe "routes for Thresholds", :type => :routing do
  it "should route to thresholds index" do
    expect(get("/plugin/alerts/collections/1/thresholds")).
      to route_to(
        controller: 'thresholds',
        action: 'index',
        collection_id: '1'
      )
  end
end
