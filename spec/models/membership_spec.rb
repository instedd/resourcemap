require 'spec_helper'

describe Membership do
  it { should belong_to :user }
  it { should belong_to :collection }
  it { should have_one :read_sites_permission }
  it { should have_one :write_sites_permission }

  let(:collection) { Collection.make }
  let(:user) { User.make }
  let(:membership) { collection.memberships.create! :user_id => user.id }
  let(:layer) { collection.layers.make }

  context "layer access" do
    let(:user2) { User.make }
    let(:membership2) { collection.memberships.create! :user_id => user2.id }

    context "when no access already exists" do
      it "grants read access to layer" do
        membership2.set_layer_access :verb => :read, :access => true, :layer_id => layer.id

        lms = LayerMembership.all
        lms.length.should eq(1)
        lms[0].collection_id.should eq(collection.id)
        lms[0].layer_id.should eq(layer.id)
        lms[0].user_id.should eq(user2.id)
        lms[0].read.should be_true
        lms[0].write.should be_false
      end

      it "grants read access to all layers" do
        membership2.set_layer_access :verb => :read, :access => true

        lms = LayerMembership.all
        lms.length.should eq(1)
        lms[0].collection_id.should eq(collection.id)
        lms[0].layer_id.should be_nil
        lms[0].user_id.should eq(user2.id)
        lms[0].read.should be_true
        lms[0].write.should be_false
      end
    end

    context "when access already exists" do
      it "grants read access" do
        LayerMembership.create! :collection_id => collection.id, :layer_id => layer.id, :user_id => user2.id, :read => false, :write => true

        membership2.set_layer_access :verb => :read, :access => true, :layer_id => layer.id

        lms = LayerMembership.all
        lms.length.should eq(1)
        lms[0].collection_id.should eq(collection.id)
        lms[0].layer_id.should eq(layer.id)
        lms[0].user_id.should eq(user2.id)
        lms[0].read.should be_true
        lms[0].write.should be_true
      end

      it "revokes read access" do
        LayerMembership.create! :collection_id => collection.id, :layer_id => layer.id, :user_id => user2.id, :read => true, :write => false

        membership2.set_layer_access :verb => :read, :access => false, :layer_id => layer.id

        LayerMembership.exists?.should be_false
      end
    end
  end

  context "on destroy" do
    it "destroys collection layer memberships" do

      collection.layer_memberships.create! :user_id => user.id, :layer_id => layer.id, :read => true, :write => true

      membership.destroy

      collection.memberships.exists?.should be_false
      collection.layer_memberships.exists?.should be_false
    end
  end

  describe "sites permission" do
    it "should include read permission" do
      read_permission = membership.create_read_sites_permission all_sites: true
      membership.sites_permission.should include(read: read_permission)
    end

    it "should include write permission" do
      write_permission = membership.create_write_sites_permission all_sites: true
      membership.sites_permission.should include(write: write_permission)
    end

    context "when user is collection admin" do
      it "should allow read for all sites" do
        membership.admin = true
        membership.sites_permission[:read].all_sites.should be true
      end

      it "should allow write for all sites" do
        membership.admin = true
        membership.sites_permission[:write].all_sites.should be true
      end
    end
  end
end
