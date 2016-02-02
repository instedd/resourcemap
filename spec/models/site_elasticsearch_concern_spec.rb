require 'spec_helper'

describe Site::ElasticsearchConcern, :type => :model do
  let(:collection) { Collection.make }
  let(:layer) { collection.layers.make }
  let(:beds_field) { layer.numeric_fields.make :code => 'beds' }
  let(:tables_field) { layer.numeric_fields.make :code => 'tables' }
  let!(:threshold) { collection.thresholds.make is_all_site: true, message_notification: "alert", conditions: [ {field: beds_field.es_code, op: 'lt', value: 10} ] }

  it "stores in index after create" do
    site = collection.sites.make :properties => {beds_field.es_code => 10, tables_field.es_code => 20}

    client = Elasticsearch::Client.new
    results = client.search index: site.index_name
    results = results["hits"]["hits"]
    expect(results[0]["_id"].to_i).to eq(site.id)
    expect(results[0]["_source"]["name"]).to eq(site.name)
    expect(results[0]["_source"]["lat_analyzed"]).to eq(site.lat.to_s)
    expect(results[0]["_source"]["lng_analyzed"]).to eq(site.lng.to_s)
    expect(results[0]["_source"]["location"]["lat"]).to be_within(1e-06).of(site.lat.to_f)
    expect(results[0]["_source"]["location"]["lon"]).to be_within(1e-06).of(site.lng.to_f)
    expect(results[0]["_source"]["properties"][beds_field.es_code].to_i).to eq(site.properties[beds_field.es_code])
    expect(results[0]["_source"]["properties"][tables_field.es_code].to_i).to eq(site.properties[tables_field.es_code])
    expect(Site.parse_time(results[0]["_source"]["created_at"]).to_i).to eq(site.created_at.to_i)
    expect(Site.parse_time(results[0]["_source"]["updated_at"]).to_i).to eq(site.updated_at.to_i)
  end

  it "removes from index after destroy" do
    site = collection.sites.make
    site.destroy

    client = Elasticsearch::Client.new
    results = client.search index: site.index_name
    expect(results["hits"]["hits"].length).to eq(0)
  end

  it "stores sites without lat and lng in index" do
    group = collection.sites.make :lat => nil, :lng => nil
    site = collection.sites.make

    client = Elasticsearch::Client.new
    results = client.search index: site.index_name
    expect(results["hits"]["hits"].length).to eq(2)
  end

  it "should stores alert in index" do
    collection.selected_plugins = ['alerts']
    collection.save
    site = collection.sites.make properties: { beds_field.es_code => 9 }

    client = Elasticsearch::Client.new
    results = client.search index: collection.index_name, type: 'site', body: {
      filter: {term: {alert: true}}
    }
    expect(results["hits"]["hits"].length).to eq(1)
  end

  describe "parse_time" do
    it "parses correct time" do
      str = "20140522T063835.000+0000"
      expect(Site.parse_time(str)).to eq(Time.zone.parse(str))
    end
  end
end
