require 'spec_helper'

describe Search do
  let!(:collection) { Collection.make }
  let!(:site1) { collection.sites.make :properties => {'beds' => 5, 'tables' => 1} }
  let!(:site2) { collection.sites.make :properties => {'beds' => 10, 'tables' => 2} }
  let!(:site3) { collection.sites.make :properties => {'beds' => 20, 'tables' => 3} }

  it "searches by equality" do
    search = collection.new_search
    search.where beds: 10
    results = search.results
    results.length.should eq(1)
    results[0]['_id'].to_i.should eq(site2.id)
  end

  it "searches by equality of two properties" do
    search = collection.new_search
    search.where beds: 10, tables: 2
    results = search.results
    results.length.should eq(1)
    results[0]['_id'].to_i.should eq(site2.id)
  end

  it "searches by equality of two properties but doesn't find" do
    search = collection.new_search
    search.where beds: 10, tables: 1
    search.results.length.should eq(0)
  end
end
