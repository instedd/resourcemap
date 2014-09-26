require 'spec_helper'

describe SiteHistory, :type => :model do
  it { is_expected.to belong_to :site }

  it "should create ES index" do
    index_name = Collection.index_name 32, snapshot: "last_year"

    client = Elasticsearch::Client.new
    client.indices.create index: index_name

    begin
      site_history = SiteHistory.make

      site_history.store_in index_name

      expect(client.indices.exists(index: index_name)).to be_truthy

      results = client.search index: index_name
      results = results["hits"]["hits"]

      expect(results.length).to eq(1)
      expect(results.first["_source"]["name"]).to eq(site_history.name)
      expect(results.first["_source"]["id"]).to eq(site_history.site_id)
      expect(results.first["_source"]["properties"]).to eq(site_history.properties)
      expect(results.first["_source"]["location"]["lat"]).to eq(site_history.lat)
      expect(results.first["_source"]["location"]["lon"]).to eq(site_history.lng)
    ensure
      client.indices.delete index: index_name
    end
  end

  it "should update version number when the site changes" do
    site = Site.make
    expect(site.histories.count).to eq(1)
    expect(site.current_history.version).to eq(1)

    site.name = "Other"
    site.save!

    expect(site.histories.count).to eq(2)
    expect(site.current_history.version).to eq(2)
  end

  it "should add which user edited on site changing" do
    user = User.make
    site = Site.make user: user
    expect(site.histories.count).to eq(1)

    site.name = "Other"
    site.save!

    expect(site.histories.count).to eq(2)
    expect(site.current_history.user_id).to eq(user.id)
  end

end

