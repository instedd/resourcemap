require 'spec_helper'

describe Search do
  let!(:collection) { Collection.make }

  context "search by property" do
    let!(:site1) { collection.sites.make :properties => {'beds' => 5, 'tables' => 1} }
    let!(:site2) { collection.sites.make :properties => {'beds' => 10, 'tables' => 2} }
    let!(:site3) { collection.sites.make :properties => {'beds' => 20, 'tables' => 3} }

    it "searches by equality" do
      search = collection.new_search
      search.where beds: 10
      assert_results search, site2
    end

    it "searches by equality of two properties" do
      search = collection.new_search
      search.where beds: 10, tables: 2
      assert_results search, site2
    end

    it "searches by equality of two properties but doesn't find" do
      search = collection.new_search
      search.where beds: 10, tables: 1
      search.results.length.should eq(0)
    end

    it "searches with lt" do
      search = collection.new_search
      search.lt :beds, 8
      assert_results search, site1
    end

    it "searches with lte" do
      search = collection.new_search
      search.lte :beds, 10
      assert_results search, site1, site2
    end

    it "searches with gt" do
      search = collection.new_search
      search.gt :beds, 18
      assert_results search, site3
    end

    it "searches with gte" do
      search = collection.new_search
      search.gte :beds, 10
      assert_results search, site2, site3
    end

    it "searches with combined properties" do
      search = collection.new_search
      search.lt :beds, 8
      search.gte :tables, 1
      assert_results search, site1
    end

    it "searches with ops" do
      search = collection.new_search
      search.op '<', :beds, 8
      search.op '>=', :tables, 1
      assert_results search, site1
    end
  end

  def assert_results(search, *sites)
    search.results.map{|r| r['_id'].to_i}.sort.should =~ sites.map(&:id)
  end
end
