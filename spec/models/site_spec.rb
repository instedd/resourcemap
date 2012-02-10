require 'spec_helper'

describe Site do
  it { should belong_to :collection }
  it { should belong_to :parent }

  context "tire" do
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

    it "removes from index after destroy" do
      site = Site.make
      site.destroy

      search = Tire::Search::Search.new site.index_name
      search.perform.results.length.should eq(0)
    end

    it "doesn't store groups in index" do
      site = Site.make :group => true

      sleep 0.2 # TODO: shouldn't be necessary... :-(

      search = Tire::Search::Search.new site.index_name
      search.perform.results.length.should eq(0)
    end
  end
end
