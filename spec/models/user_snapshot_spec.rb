require 'spec_helper'

describe UserSnapshot do
  let!(:collection) { Collection.make }

  it "should delete previous snapshot per user when creating a new one" do
    user = User.make

    snapshot1 = collection.snapshots.create! date: Date.yesterday, name: 'snp1'
    snapshot1.user_snapshots.create! user: user

    snapshot_for_user = UserSnapshot.where user_id: user.id
    snapshot_for_user.count.should eq(1)
    snapshot_for_user.first.snapshot.name.should eq("snp1")

    snapshot2 = collection.snapshots.create! date: Time.now , name: 'snp2'
    snapshot2.user_snapshots.create! user: user
    snapshot_for_user_new = UserSnapshot.where user_id: user.id
    snapshot_for_user_new.count.should eq(1)
    snapshot_for_user_new.first.snapshot.name.should eq("snp2")

  end

end
