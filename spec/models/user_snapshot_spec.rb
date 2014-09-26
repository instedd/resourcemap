require 'spec_helper'

describe UserSnapshot, :type => :model do
  let(:collection) { Collection.make }
  let(:user) { User.make }
  let(:snapshot1) { collection.snapshots.create! date: Date.yesterday, name: 'snp1' }
  let!(:user_snapshot) { snapshot1.user_snapshots.create! user: user, collection: collection }

  it "should delete previous snapshot per user and collection when creating a new one" do
    snapshot_for_user = UserSnapshot.where user_id: user.id, collection_id: collection.id
    expect(snapshot_for_user.count).to eq(1)
    expect(snapshot_for_user.first.snapshot.name).to eq("snp1")

    snapshot2 = collection.snapshots.create! date: Time.now , name: 'snp2'
    snapshot2.user_snapshots.create! user: user, collection: collection
    snapshot_for_user_new = UserSnapshot.where user_id: user.id, collection_id: collection
    expect(snapshot_for_user_new.count).to eq(1)
    expect(snapshot_for_user_new.first.snapshot.name).to eq("snp2")
  end

  describe "for" do
    it "returns the corresponding UserSnapshot" do
      s = UserSnapshot.for user, collection

      expect(s.snapshot.name).to eq('snp1')
    end

    it "returns a valid unsaved UserSnapshot instance when there is not a previously saved one" do
      user2 = User.make

      s = UserSnapshot.for user2, collection

      expect(s).not_to eq(nil)
      expect(s.new_record?).to eq(true)
      expect(s.collection).to eq(collection)
      expect(s.user).to eq(user2)
    end
  end

  describe "at_present?" do
    it "is false if there's a snapshot loaded" do
      expect(user_snapshot.at_present?).to eq(false)
    end

    it "is true if there isn't any snapshot loaded" do
      s = UserSnapshot.new user: User.make, collection: collection
      expect(s.at_present?).to eq(true)
    end
  end

  describe "go_back_to_present" do
    it "does not persist the UserSnapshot if it wasn't persisted before" do
      s = UserSnapshot.new user: User.make, collection: collection
      s.go_back_to_present!
      expect(s.new_record?).to eq(true)
    end

    it "persists changes immediately" do
      user_snapshot.go_back_to_present!
      user_snapshot.reload
      expect(user_snapshot.at_present?).to eq(true)
    end

    it "goes back to present if a snapshot was loaded" do
      user_snapshot.go_back_to_present!
      expect(user_snapshot.at_present?).to eq(true)
    end

    it "stays at present if a snapshot wasn't loaded" do
      s = UserSnapshot.new user: User.make, collection: collection

      s.go_back_to_present!

      expect(s.at_present?).to eq(true)
    end
  end

  describe "go_to" do
    it "returns false and does nothing if there is not any snapshot with the given name" do
      snapshot_before = user_snapshot.snapshot

      expect(user_snapshot.go_to!('a_snapshot_that_doesnt_exist')).to eq(false)

      expect(user_snapshot.snapshot).to eq(snapshot_before)
    end

    it "loads a snapshot with the given name" do
      my_snapshot = collection.snapshots.create! date: Time.now , name: 'my snapshot'

      expect(user_snapshot.go_to!('my snapshot')).to eq(true)

      expect(user_snapshot.snapshot).to eq(user_snapshot.snapshot)
      expect(user_snapshot.snapshot.name).to eq('my snapshot')
    end
  end
end
