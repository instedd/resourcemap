require 'spec_helper'

describe Collection::GeomConcern do
  let(:collection) { Collection.make }

  it "calculates center from children sites" do
    site1 = collection.sites.make :lat => 30, :lng => 20
    site2 = collection.sites.make :lat => 40, :lng => 30

    collection.reload
    collection.lat.to_f.should eq(35.0)
    collection.lng.to_f.should eq(25.0)
  end

  it "calculates center from children sites is not weighted" do
    site1 = collection.sites.make :lat => 30, :lng => 20
    site2 = collection.sites.make :lat => 40, :lng => 30
    site3 = collection.sites.make :lat => 40, :lng => 30

    collection.reload
    collection.lat.to_f.should eq(35.0)
    collection.lng.to_f.should eq(25.0)
  end

  it "calculates bounding box from children" do
    site1 = collection.sites.make :lat => 30, :lng => 20
    site2 = collection.sites.make :lat => 40, :lng => 30
    site3 = collection.sites.make :lat => 45, :lng => 40

    collection.reload
    collection.min_lat.to_f.should eq(30.0)
    collection.max_lat.to_f.should eq(45.0)
    collection.min_lng.to_f.should eq(20.0)
    collection.max_lng.to_f.should eq(40.0)
  end

  it "ignores sites without lat/lng", :focus => true do
    site1 = collection.sites.make :lat => nil, :lng => nil
    site2 = collection.sites.make :lat => 30, :lng => 20

    collection.reload
    collection.lat.to_f.should eq(30.0)
    collection.lng.to_f.should eq(20.0)
  end

  it "calculates center from children sites after destroy" do
    site1 = collection.sites.make :lat => 30, :lng => 20
    site2 = collection.sites.make :lat => 40, :lng => 30
    site2.destroy

    collection.reload
    collection.lat.to_f.should eq(30.0)
    collection.lng.to_f.should eq(20.0)
  end
end
