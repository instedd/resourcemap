require 'spec_helper'

describe Collection::ElasticsearchConcern do
  let(:collection) { Collection.make }

  it "creates index on create" do
    client = Elasticsearch::Client.new
    client.indices.exists(index: collection.index_name).should be_truthy
  end

  it "destroys index on destroy" do
    collection.destroy

    client = Elasticsearch::Client.new
    client.indices.exists(index: collection.index_name).should be_falsey
  end

  it "create proper index name" do
    index_name = Collection.index_name 32
    index_name.should eq("collection_test_32")

    index_name_for_snapshot = Collection.index_name 32, snapshot_id: 12
    index_name_for_snapshot.should eq("collection_test_32_12")

    collection = Collection.make
    index_name_for_user_without_collection = Collection.index_name collection.id, user: User.make
    index_name_for_user_without_collection.should eq("collection_test_#{collection.id}")

    collection = Collection.make
    index_name_for_user_without_snapshot = Collection.index_name(collection.id, user: User.make)
    index_name_for_user_without_snapshot.should eq("collection_test_#{collection.id}")

    user = User.make
    collection = Collection.make
    collection.snapshots.create! date: Time.now, name: 'last_year'
    snapshot = collection.snapshots.first
    UserSnapshot.make :user => user, :snapshot => snapshot
    index_name_for_user_with_snapshot = Collection.index_name(collection.id, user: user)
    index_name_for_user_with_snapshot.should eq("collection_test_#{collection.id}_#{snapshot.id}")
  end
end
