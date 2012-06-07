require 'spec_helper'

describe Collection do
  it { should validate_presence_of :name }
  it { should have_many :memberships }
  it { should have_many :users }
  it { should have_many :layers }
  it { should have_many :fields }
  it { should have_many :thresholds }

  let!(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make_unsaved }
  let!(:layer) { collection.layers.make user: user, fields_attributes: [{kind: 'numeric', code: 'foo', name: 'Foo', ord: 1}] }
  let!(:field) { layer.fields.first }

  context "max value" do
    it "gets max value for property that exists" do
      collection.sites.make :properties => {field.es_code => 10}
      collection.sites.make :properties => {field.es_code => 20}, :lat => nil, :lng => nil
      collection.sites.make :properties => {field.es_code => 5}

      collection.max_value_of_property(field.es_code).should eq(20)
    end
  end

  describe "thresholds test" do
    let!(:properties) { { field.es_code => 9 } }

    it "should return false when there is no threshold" do
      collection.thresholds_test(properties).should be_false
    end

    it "should return false when no threshold is hit" do
      collection.thresholds.make conditions: [ field: field.es_code, op: :gt, value: 10 ]
      collection.thresholds_test(properties).should be_false
    end

    it "should return true when threshold 1 is hit" do
      collection.thresholds.make conditions: [ field: field.es_code, op: :lt, value: 10 ]
      collection.thresholds_test(properties).should be_true
    end

    it "should return true when threshold 2 is hit" do
      collection.thresholds.make conditions: [ field: field.es_code, op: :gt, value: 10 ]
      collection.thresholds.make conditions: [ field: field.es_code, op: :eq, value: 9 ]
      collection.thresholds_test(properties).should be_true
    end
  end

  describe "SMS query" do
    pending do
      it "should prepare response_sms" do
        option = {:field_code => "AB", :field_id => 2}
        result = [{"_source"=>{"id"=>1, "name"=>"Siem Reap Health Center", "properties"=>{"1"=>15, "2"=>40, "3"=>6}}}]
        collection.response_prepare(option[:field_code], option[:field_id], result).should eq("[\"#{option[:field_code]}\"] in #{[result[0]["_source"]["name"],40].join(", ")}")
      end
    end

    describe "Operator parser" do
      it "should return operator for search class" do
        collection.operator_parser(">").should eq("gt")
        collection.operator_parser("<").should eq("lt")
        collection.operator_parser("=>").should eq("gte")
        collection.operator_parser("=<").should eq("lte")
        collection.operator_parser(">=").should eq("gte")
        collection.operator_parser("<=").should eq("lte")
      end
    end
  end

  describe "Snapshot tests" do
    before(:each) do
      stub_time '2011-01-01 10:00:00'

      collection.sites.make name: 'site1 last year'
      collection.sites.make name: 'site2 last year'

      stub_time '2012-06-05 12:17:58'

      collection.sites.make name: 'site3 today'
      collection.sites.make name: 'site4 today'

    end

    it "should create snapshot for last year" do
      date = '2011-01-01 10:00:00'.to_time

      collection.create_snapshot("last_year", date)

      snapshots = collection.snapshots
      snapshots.count.should eq(1)

      snapshot = snapshots.first
      snapshot.name.should eq("last_year")
      snapshot.date.should eq(date)
    end

    it "should create index with sites" do
      date = '2011-01-01 10:00:00'.to_time
      collection.create_snapshot("last_year", date)

      index_name = Collection.index_name collection.id, snapshot: "last_year"
      search = Tire::Search::Search.new index_name
      search.perform.results.length.should eq(2)
    end

    it 'should not include site of other collections in index' do
      stub_time '2011-01-01 10:00:00'
      Site.make collection_id: 34

      date = '2011-01-01 10:00:00'.to_time
      collection.create_snapshot("last_year", date)
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
end
