require "./../spec_helper"

describe Site do
  it "should translate elasticsearch date" do
    Site.api_date("20140131T002014.000+0000").should eq("2014-01-31T00:20:14.000Z")
  end
end
