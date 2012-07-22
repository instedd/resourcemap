require 'spec_helper'

describe "routes for Thresholds" do
  it "should route to thresholds index" do
    get("/plugin/alerts/collections/1/thresholds").
      should route_to(
        controller: 'thresholds',
        action: 'index',
        collection_id: '1'
      )
  end
end
