require 'spec_helper'

describe User do
  it { should have_many :memberships }
  it { should have_many :collections }

  it "creates a collection" do
    user = User.make
    collection = Collection.make_unsaved
    user.create_collection(collection).should eq(collection)
    user.collections.should eq([collection])
  end

  it "fails to create a collection if invalid" do
    user = User.make
    collection = Collection.make_unsaved
    collection.name = nil
    user.create_collection(collection).should be_false
    user.collections.should be_empty
  end
end
