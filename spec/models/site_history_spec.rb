require 'spec_helper'

describe SiteHistory do
  it { should belong_to :site }

  it "should create ES index" do
    index_name = Collection.index_name 32, snapshot: "last_year"

    client = Elasticsearch::Client.new
    client.indices.create index: index_name

    begin
      site_history = SiteHistory.make

      site_history.store_in index_name

      client.indices.exists(index: index_name).should be_true

      results = client.search index: index_name
      results = results["hits"]["hits"]

      results.length.should eq(1)
      results.first["_source"]["name"].should eq(site_history.name)
      results.first["_source"]["id"].should eq(site_history.site_id)
      results.first["_source"]["properties"].should eq(site_history.properties)
      results.first["_source"]["location"]["lat"].should eq(site_history.lat)
      results.first["_source"]["location"]["lon"].should eq(site_history.lng)
    ensure
      client.indices.delete index: index_name
    end
  end

  it "should update version number when the site changes" do
    site = Site.make
    site.histories.count.should eq(1)
    site.current_history.version.should eq(1)

    site.name = "Other"
    site.save!

    site.histories.count.should eq(2)
    site.current_history.version.should eq(2)
  end

  it "should add which user edited on site changing" do
    user = User.make
    site = Site.make user: user
    site.histories.count.should eq(1)

    site.name = "Other"
    site.save!

    site.histories.count.should eq(2)
    site.current_history.user_id.should eq(user.id)
  end

end

