require 'spec_helper'

describe Collection::ElasticsearchConcern do
  auth_scope(:user) { User.make }
  let(:collection) { user.create_collection Collection.make_unsaved }

  it "creates index on create" do
    client = Elasticsearch::Client.new
    client.indices.exists(index: collection.index_name).should be_true
  end

  it "destroys index on destroy" do
    collection.destroy

    client = Elasticsearch::Client.new
    client.indices.exists(index: collection.index_name).should be_false
  end

  it "create proper index name" do
    index_name = Collection.index_name 32
    index_name.should eq("collection_test_32")

    index_name_for_snapshot = Collection.index_name 32, snapshot_id: 12
    index_name_for_snapshot.should eq("collection_test_32_12")

    index_name_for_user_without_snapshot = Collection.index_name(collection.id, user: user)
    index_name_for_user_without_snapshot.should eq("collection_test_#{collection.id}")

    collection.snapshots.create! date: Time.now, name: 'last_year'
    snapshot = collection.snapshots.first
    UserSnapshot.make :user => user, :snapshot => snapshot
    index_name_for_user_with_snapshot = Collection.index_name(collection.id, user: user)
    index_name_for_user_with_snapshot.should eq("collection_test_#{collection.id}_#{snapshot.id}")
  end
end
