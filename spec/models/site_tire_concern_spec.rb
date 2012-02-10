require 'spec_helper'

describe Site::TireConcern do
  it "stores in index after create" do
    site = Site.make :properties => {:beds => 10}

    search = Tire::Search::Search.new site.index_name
    results = search.perform.results
    results.length.should eq(1)
    results[0]["_id"].to_i.should eq(site.id)
    results[0]["_source"]["location"]["lat"].should be_within(1e-06).of(site.lat.to_f)
    results[0]["_source"]["location"]["lon"].should be_within(1e-06).of(site.lng.to_f)
    results[0]["_source"]["properties"]["beds"].to_i.should eq(site.properties[:beds])
  end

  it "stores hierarchy in index" do
    collection = Collection.make
    site1 = collection.sites.make
    site2 = collection.sites.make :parent_id => site1.id
    site3 = collection.sites.make :parent_id => site2.id

    search = Tire::Search::Search.new collection.index_name
    results = search.perform.results
    result = results.select{|x| x["_id"].to_s == site3.id.to_s}.first
    result["_source"]["parents"].should eq([site1.id, site2.id])
  end

  it "removes from index after destroy" do
    site = Site.make
    site.destroy

    search = Tire::Search::Search.new site.index_name
    search.perform.results.length.should eq(0)
  end

  it "doesn't store groups in index" do
    site = Site.make :group => true

    search = Tire::Search::Search.new site.index_name
    search.perform.results.length.should eq(0)
  end
end
