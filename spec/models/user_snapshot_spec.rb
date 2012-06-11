require 'spec_helper'

describe UserSnapshot do
  let!(:collection) { Collection.make }

  it "should delete previous snapshot per user when creating a new one" do
    user = User.make

    snapshot1 = collection.snapshots.create! date: Date.yesterday, name: 'snp1'
    UserSnapshot.make user: user, snapshot: snapshot1

    snapshot_for_user = UserSnapshot.where user_id: user.id
    snapshot_for_user.count.should eq(1)
    snapshot_for_user.first.snapshot.name.should eq("snp1")

    snapshot2 = collection.snapshots.create! date: Time.now , name: 'snp2'
    UserSnapshot.make user: user, snapshot: snapshot2
    snapshot_for_user_new = UserSnapshot.where user_id: user.id
    snapshot_for_user_new.count.should eq(1)
    snapshot_for_user_new.first.snapshot.name.should eq("snp2")

  end

  it "should get current snapshot per user" do
    user = User.make
    snapshot1 = collection.snapshots.create! date: Date.yesterday, name: 'snp1'
    UserSnapshot.make user: user, snapshot: snapshot1

    snapshots = UserSnapshot.get_for(user, collection)
    snapshots.count.should eq(1)
    snapshots.first.user_id.should eq(user.id)
    snapshots.first.snapshot.collection_id.should eq(collection.id)

  end

end
