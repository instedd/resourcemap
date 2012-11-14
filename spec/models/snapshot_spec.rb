require 'spec_helper'

describe Snapshot do
  describe "validations" do
    let!(:snapshot) { Snapshot.make }

    it { should validate_uniqueness_of(:name).scoped_to(:collection_id) }
  end

  let!(:collection) { Collection.make }

  before(:each) do
    stub_time '2011-01-01 10:00:00 -0500'

    layer = collection.layers.make
    @field = layer.fields.make code: 'beds', kind: 'numeric'

    @site1 = collection.sites.make name: 'site1 last year'
    @site2 = collection.sites.make name: 'site2 last year'

    stub_time '2012-06-05 12:17:58 -0500'
    @field2 = layer.fields.make code: 'beds2', kind: 'numeric'

    @site3 = collection.sites.make name: 'site3 today'
    @site4 = collection.sites.make name: 'site4 today'
  end

  it "should create index with sites" do
    date = '2011-01-01 10:00:00 -0500'.to_time
    snapshot = collection.snapshots.create! date: date, name: 'last_year'

    index_name = Collection.index_name collection.id, snapshot_id: snapshot.id
    search = Tire::Search::Search.new index_name

    search.perform.results.map { |x| x['_source']['id'] }.sort.should eq([@site1.id, @site2.id])

    # Also check mapping
    snapshot.index.mapping['site']['properties']['properties']['properties'].should eq({@field.es_code => {'type' => 'long'}})
  end

  it "should destroy index on destroy" do
    date = '2011-01-01 10:00:00 -0500'.to_time

    snapshot = collection.snapshots.create! date: date, name: 'last_year'
    snapshot.destroy

    index_name = Collection.index_name collection.id, snapshot_id: snapshot.id
    Tire::Index.new(index_name).exists?.should be_false
  end

  its "collection should have histories" do
    date = Time.now

    site_histories = collection.site_histories.at_date(date)
    site_histories.count.should eq(4)

    layer_histories = collection.layer_histories.at_date(date)
    layer_histories.count.should eq(1)

    field_histories = collection.field_histories.at_date(date)
    field_histories.count.should eq(2)
  end

  it "should delete history when collection is destroyed" do
    collection.destroy

    collection.site_histories.count.should eq(0)
    collection.layer_histories.count.should eq(0)
    collection.field_histories.count.should eq(0)
  end

  it "should delete snapshots when collection is destroyed" do
    collection.snapshots.create! date: Time.now, name: 'last_year'
    collection.snapshots.count.should eq(1)

    collection.destroy

    collection.snapshots.count.should eq(0)
  end

  it "should delete userSnapshot if collection is destroyed" do
    snapshot = collection.snapshots.create! date: Time.now, name: 'last_year'
    user = User.make
    snapshot.user_snapshots.create! user: user
    snapshot.user_snapshots.count.should eq(1)

    collection.destroy

    UserSnapshot.where(user_id: user.id, snapshot_id: snapshot.id).count.should eq(0)
  end

end
