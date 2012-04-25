require 'spec_helper'

describe User do
  it { should have_many :memberships }
  it { should have_many :collections }

  it "creates a collection" do
    user = User.make
    collection = Collection.make_unsaved
    user.create_collection(collection).should eq(collection)
    user.collections.should eq([collection])
    user.memberships.first.should be_admin
  end

  it "fails to create a collection if invalid" do
    user = User.make
    collection = Collection.make_unsaved
    collection.name = nil
    user.create_collection(collection).should be_false
    user.collections.should be_empty
  end

  context "admins?" do
    let!(:user) { User.make }
    let!(:collection) { user.create_collection Collection.make_unsaved }

    it "admins a collection" do
      user.admins?(collection).should be_true
    end

    it "doesn't admin a collection if belongs but not admin" do
      user2 = User.make
      user2.memberships.create! :collection_id => collection.id
      user2.admins?(collection).should be_false
    end

    it "doesn't admin a collection if doesn't belong" do
      User.make.admins?(collection).should be_false
    end
  end

  context "activities" do
    let!(:user) { User.make }
    let!(:collection) { user.create_collection Collection.make_unsaved }

    before(:each) do
      Activity.delete_all
    end

    it "returns activities for user membership" do
      Activity.make collection_id: collection.id, user_id: user.id, kind: 'collection_created'

      user.activities.length.should eq(1)
    end

    it "doesn't return activities for user membership" do
      user2 = User.make

      Activity.make collection_id: collection.id, user_id: user.id, kind: 'collection_created'

      user2.activities.length.should eq(0)
    end
  end
end
