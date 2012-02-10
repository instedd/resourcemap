require 'spec_helper'

describe Search do
  it "searches based on no collection" do
    site = Site.make

    search = Search.new []
    search.results.should eq({})
  end

  it "searches based on collection id found" do
    site = Site.make

    search = Search.new site.collection_id
    search.results[:sites].should eq([{:id => site.id, :lat => site.lat.to_f, :lng => site.lng.to_f}])
  end

  it "searches based on collection id not found" do
    site = Site.make
    other_collection = Collection.make

    search = Search.new other_collection.id
    search.results[:sites].should be_nil
  end

  it "searches based on many collection ids found" do
    site1 = Site.make :lat => 45, :lng => 90
    site2 = Site.make :lat => -45, :lng => -90

    search = Search.new [site1.collection_id, site2.collection_id]
    search.results[:sites].length.should eq(2)
  end

  it "searches based on collection id and bounds found" do
    site = Site.make :lat => 10, :lng => 20

    search = Search.new site.collection_id
    search.bounds = {:s => 9, :n => 11, :w => 19, :e => 21}
    search.results[:sites].length.should eq(1)
  end

  it "searches based on collection id and bounds not found" do
    site = Site.make :lat => 10, :lng => 20

    search = Search.new site.collection_id
    search.bounds = {:s => 11, :n => 12, :w => 21, :e => 22}
    search.results[:sites].should be_nil
  end
end
