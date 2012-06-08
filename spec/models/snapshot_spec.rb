require 'spec_helper'

describe Snapshot do
  describe "validations" do
    let!(:snapshot) { Snapshot.make }

    it { should validate_uniqueness_of(:name).scoped_to(:collection_id) }
  end

  let!(:collection) { Collection.make }

  before(:each) do
    stub_time '2011-01-01 10:00:00'

    layer = collection.layers.make
    @field = layer.fields.make code: 'beds', kind: 'numeric'

    collection.sites.make name: 'site1 last year'
    collection.sites.make name: 'site2 last year'

    stub_time '2012-06-05 12:17:58'

    @field2 = layer.fields.make code: 'beds', kind: 'numeric'

    collection.sites.make name: 'site3 today'
    collection.sites.make name: 'site4 today'
  end

  it "should create index with sites" do
    date = '2011-01-01 10:00:00'.to_time
    snapshot = collection.snapshots.create! date: date, name: 'last_year'

    index_name = Collection.index_name collection.id, snapshot: "last_year"
    search = Tire::Search::Search.new index_name
    search.perform.results.length.should eq(2)

    # Also check mapping
    snapshot.index.mapping['site']['properties']['properties']['properties'].should eq({@field.es_code => {'type' => 'long'}})
  end

  it 'should not include site of other collections in index' do
    stub_time '2011-01-01 10:00:00'
    Site.make collection_id: 34

    date = '2011-01-01 10:00:00'.to_time
    collection.snapshots.create! date: date, name: "last_year"
    index_name = Collection.index_name collection.id, snapshot: "last_year"
    search = Tire::Search::Search.new index_name
    search.perform.results.length.should eq(2)

  end

  it "should delete history when collection is destroyed" do
    collection_id = collection.id
    collection.layers.make
    collection.fields.make

    date = Time.now

    site_histories = collection.site_histories.at_date(date)
    site_histories.count.should eq(4)

    layer_histories = collection.layer_histories.at_date(date)
    layer_histories.count.should eq(1)

    field_histories = collection.field_histories.at_date(date)

    field_histories.count.should eq(1)

    collection.destroy

    new_site_histories = collection.site_histories.at_date(date)
    new_site_histories.count.should eq(0)

    new_layer_histories = collection.layer_histories.at_date(date)
    new_layer_histories.count.should eq(0)

    new_field_histories = collection.field_histories.at_date(date)
    new_field_histories.count.should eq(0)
  end
end
