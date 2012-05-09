require 'spec_helper'

describe Site::TireConcern do
  it "stores in index after create" do
    site = Site.make :properties => {:beds => 10}

    search = Tire::Search::Search.new site.index_name
    results = search.perform.results
    results.length.should eq(1)
    results[0]["_id"].to_i.should eq(site.id)
    results[0]["_source"]["name"].should eq(site.name)
    results[0]["_source"]["location"]["lat"].should be_within(1e-06).of(site.lat.to_f)
    results[0]["_source"]["location"]["lon"].should be_within(1e-06).of(site.lng.to_f)
    results[0]["_source"]["properties"][Site.encode_elastic_search_keyword("beds")].to_i.should eq(site.properties[:beds])
    Site.parse_date(results[0]["_source"]["created_at"]).to_i.should eq(site.created_at.to_i)
    Site.parse_date(results[0]["_source"]["updated_at"]).to_i.should eq(site.updated_at.to_i)
  end

  it "removes from index after destroy" do
    site = Site.make
    site.destroy

    search = Tire::Search::Search.new site.index_name
    search.perform.results.length.should eq(0)
  end

  it "stores sites without lat and lng in index" do
    collection = Collection.make
    group = collection.sites.make :lat => nil, :lng => nil
    site = collection.sites.make

    search = Tire::Search::Search.new collection.index_name
    search.perform.results.length.should eq(2)
  end

  it "should stores alert in index" do
    collection = Collection.make
    threshold = collection.thresholds.make conditions: [ field: 'beds', is: :lt, value: 10 ]
    site = collection.sites.make properties: { 'beds' => 9 }

    search = Tire::Search::Search.new collection.index_name
    search.query { string 'alert:true' }
    result = search.perform.results
    result.count.should eq(1)
  end
end
