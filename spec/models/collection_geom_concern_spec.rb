require 'spec_helper'

describe Collection::GeomConcern, :type => :model do
  let(:collection) { Collection.make }

  it "calculates center from children sites" do
    site1 = collection.sites.make :lat => 30, :lng => 20
    site2 = collection.sites.make :lat => 40, :lng => 30

    collection.reload
    expect(collection.lat.to_f).to eq(35.0)
    expect(collection.lng.to_f).to eq(25.0)
  end

  it "calculates center from children sites is not weighted" do
    site1 = collection.sites.make :lat => 30, :lng => 20
    site2 = collection.sites.make :lat => 40, :lng => 30
    site3 = collection.sites.make :lat => 40, :lng => 30

    collection.reload
    expect(collection.lat.to_f).to eq(35.0)
    expect(collection.lng.to_f).to eq(25.0)
  end

  it "calculates bounding box from children" do
    site1 = collection.sites.make :lat => 30, :lng => 20
    site2 = collection.sites.make :lat => 40, :lng => 30
    site3 = collection.sites.make :lat => 45, :lng => 40

    collection.reload
    expect(collection.min_lat.to_f).to eq(30.0)
    expect(collection.max_lat.to_f).to eq(45.0)
    expect(collection.min_lng.to_f).to eq(20.0)
    expect(collection.max_lng.to_f).to eq(40.0)
  end

  it "ignores sites without lat/lng", :focus => true do
    site1 = collection.sites.make :lat => nil, :lng => nil
    site2 = collection.sites.make :lat => 30, :lng => 20

    collection.reload
    expect(collection.lat.to_f).to eq(30.0)
    expect(collection.lng.to_f).to eq(20.0)
  end

  it "calculates center from children sites after destroy" do
    site1 = collection.sites.make :lat => 30, :lng => 20
    site2 = collection.sites.make :lat => 40, :lng => 30
    site2.destroy

    collection.reload
    expect(collection.lat.to_f).to eq(30.0)
    expect(collection.lng.to_f).to eq(20.0)
  end

  it "use big bounding box when removing locations from sites" do
    site1 = collection.sites.make :lat => 30, :lng => 20
    site1.lat = nil
    site1.lng = nil
    site1.save!

    collection.reload
    expect(collection.lat.to_f).to eq(0)
    expect(collection.lng.to_f).to eq(0)
    expect(collection.min_lat.to_f).to eq(-60)
    expect(collection.max_lat.to_f).to eq(60)
    expect(collection.min_lng.to_f).to eq(-150)
    expect(collection.max_lng.to_f).to eq(150)
  end
end
