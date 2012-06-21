require 'spec_helper'

describe Collection::TireConcern do
  let(:collection) { Collection.make }

  it "creates index on create" do
    Tire::Index.new(collection.index_name).exists?.should be_true
  end

  it "destroys index on destroy" do
    collection.destroy
    Tire::Index.new(collection.index_name).exists?.should be_false
  end

  it "create proper index name" do
    index_name = Collection.index_name 32
    index_name.should eq("collection_test_32")

    index_name_for_snapshot = Collection.index_name 32, snapshot: "last_year"
    index_name_for_snapshot.should eq("collection_test_32_last_year")

    collection = Collection.make
    index_name_for_user_without_collection = Collection.index_name collection.id, user: User.make
    index_name_for_user_without_collection.should eq("collection_test_#{collection.id}")

    collection = Collection.make
    index_name_for_user_without_snapshot = Collection.index_name(collection.id, user: User.make)
    index_name_for_user_without_snapshot.should eq("collection_test_#{collection.id}")

    user = User.make
    collection = Collection.make
    collection.snapshots.create! date: Time.now, name: 'last_year'
    snapshot = UserSnapshot.make :user => user, :snapshot => collection.snapshots.first
    index_name_for_user_with_snapshot = Collection.index_name(collection.id, user: user)
    index_name_for_user_with_snapshot.should eq("collection_test_#{collection.id}_last_year")

  end


end
