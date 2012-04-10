require 'spec_helper'

describe "routes for Collections" do
  it "should route to show thresholds setting" do
    get("/collections/1/thresholds_setting").
      should route_to(
        controller: 'collections', 
        action: 'thresholds_setting', 
        collection_id: '1'
      )
  end
end
