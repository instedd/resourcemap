require 'spec_helper'

describe Snapshot, :type => :model do
  describe "validations" do
    let!(:snapshot) { Snapshot.make }

    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:collection_id) }
  end

  let(:collection) { Collection.make }

  before(:each) do
    stub_time '2011-01-01 10:00:00 -0500'

    layer = collection.layers.make
    @field = layer.numeric_fields.make code: 'beds'

    @site1 = collection.sites.make name: 'site1 last year'
    @site2 = collection.sites.make name: 'site2 last year'

    stub_time '2012-06-05 12:17:58 -0500'
    @field2 = layer.numeric_fields.make code: 'beds2'

    @site3 = collection.sites.make name: 'site3 today'
    @site4 = collection.sites.make name: 'site4 today'
  end

  it "should create index with sites" do
    date = '2011-01-01 10:00:00 -0500'.to_time
    snapshot = collection.snapshots.create! date: date, name: 'last_year'

    index_name = Collection.index_name collection.id, snapshot_id: snapshot.id
    results = Elasticsearch::Client.new.search index: index_name
    results = results["hits"]["hits"]
    expect(results.map { |x| x['_source']['id'] }.sort).to eq([@site1.id, @site2.id])

    # Also check mapping
    mapping = Elasticsearch::Client.new.indices.get_mapping index: snapshot.index_name, type: 'site'
    expect(mapping[snapshot.index_name]['mappings']['site']['properties']['properties']['properties']).to eq({@field.es_code => {'type' => 'long'}})
  end

  it "should destroy index on destroy" do
    date = '2011-01-01 10:00:00 -0500'.to_time

    snapshot = collection.snapshots.create! date: date, name: 'last_year'
    snapshot.destroy

    index_name = Collection.index_name collection.id, snapshot_id: snapshot.id
    expect(Elasticsearch::Client.new.indices.exists(index: index_name)).to be_falsey
  end

  it "collection should have histories" do
    date = Time.now
    site_histories = collection.site_histories.at_date(date)
    expect(site_histories.count).to eq(4)

    layer_histories = collection.layer_histories.at_date(date)
    expect(layer_histories.count).to eq(1)

    field_histories = collection.field_histories.at_date(date)
    expect(field_histories.count).to eq(2)
  end

  it "collection should have histories for a past time" do
    date = Time.parse('2011-01-02 10:00:00 -0500')

    site_histories = collection.site_histories.at_date(date)
    expect(site_histories.count).to eq(2)

    layer_histories = collection.layer_histories.at_date(date)
    expect(layer_histories.count).to eq(1)

    field_histories = collection.field_histories.at_date(date)
    expect(field_histories.count).to eq(1)
  end

  it "should delete history when collection is destroyed" do
    collection.destroy

    expect(collection.site_histories.count).to eq(0)
    expect(collection.layer_histories.count).to eq(0)
    expect(collection.field_histories.count).to eq(0)
  end

  it "should delete snapshots when collection is destroyed" do
    collection.snapshots.create! date: Time.now, name: 'last_year'
    expect(collection.snapshots.count).to eq(1)

    collection.destroy

    expect(collection.snapshots.count).to eq(0)
  end

  it "should delete userSnapshot if collection is destroyed" do
    snapshot = collection.snapshots.create! date: Time.now, name: 'last_year'
    user = User.make
    snapshot.user_snapshots.create! user: user
    expect(snapshot.user_snapshots.count).to eq(1)

    collection.destroy

    expect(UserSnapshot.where(user_id: user.id, snapshot_id: snapshot.id).count).to eq(0)
  end

  describe "info_for_collections_ids_and_user" do
    it "should return empty hash if collections_ids is empty" do
      user = User.make
      expect(Snapshot.info_for_collections_ids_and_user([], user, "field")).to eq({})
    end
  end
end
