require 'spec_helper'

describe Site do
  it { should belong_to :collection }
  it { should belong_to :parent }

  context "tire" do
    it "stores in index after create" do
      site = Site.make

      search = Tire::Search::Search.new site.index_name
      results = search.perform.results
      results.length.should eq(1)
      results[0]["_id"].to_i.should eq(site.id)
      results[0]["_source"]["location"]["lat"].to_f.should be_within(1e-06).of(site.lat.to_f)
      results[0]["_source"]["location"]["lon"].to_f.should be_within(1e-06).of(site.lng.to_f)
    end

    it "removes from index after destroy" do
      site = Site.make
      site.destroy

      search = Tire::Search::Search.new site.index_name
      results = search.perform.results
      results.length.should eq(0)
    end
  end
end
