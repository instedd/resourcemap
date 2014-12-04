require 'spec_helper'

describe Collection::ElasticsearchConcern, :type => :model do
  let(:collection) { Collection.make }

  it "creates index on create" do
    client = Elasticsearch::Client.new
    expect(client.indices.exists(index: collection.index_name)).to be_truthy
  end

  it "destroys index on destroy" do
    collection.destroy

    client = Elasticsearch::Client.new
    expect(client.indices.exists(index: collection.index_name)).to be_falsey
  end

  describe "create proper index name" do
    it do
      index_name = Collection.index_name 32
      expect(index_name).to eq("active_collection_test_32")
    end

    it do
      index_name_for_snapshot = Collection.index_name 32, snapshot_id: 12
      expect(index_name_for_snapshot).to eq("active_collection_test_32_12")
    end

    it do
      collection = Collection.make
      index_name_for_user_without_collection = Collection.index_name collection.id, user: User.make
      expect(index_name_for_user_without_collection).to eq("active_collection_test_#{collection.id}")
    end

    it do
      collection = Collection.make
      index_name_for_user_without_snapshot = Collection.index_name(collection.id, user: User.make)
      expect(index_name_for_user_without_snapshot).to eq("active_collection_test_#{collection.id}")
    end

    it do
      user = User.make
      collection = Collection.make
      collection.snapshots.create! date: Time.now, name: 'last_year'
      snapshot = collection.snapshots.first
      UserSnapshot.make :user => user, :snapshot => snapshot
      index_name_for_user_with_snapshot = Collection.index_name(collection.id, user: user)
      expect(index_name_for_user_with_snapshot).to eq("active_collection_test_#{collection.id}_#{snapshot.id}")
    end
  end
end
