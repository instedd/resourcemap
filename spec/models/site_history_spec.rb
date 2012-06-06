require 'spec_helper'

describe SiteHistory do
  it { should belong_to :site }

  it "should create ES index" do
    index_name = Collection.index_name 32, snapshot: "last_year"
    index = Tire::Index.new index_name
    index.create

    site_history = SiteHistory.make

    site_history.store_in index

    index.exists?.should be_true

    search = Tire::Search::Search.new index_name
    search.perform.results.length.should eq(1)
    search.perform.results.first["_source"]["name"].should eq(site_history.name)

  end

end

