require 'spec_helper'

describe Membership::LayerAccessConcern do
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
        lms[0].membership_id.should eq(membership2.id)
        lms[0].layer_id.should eq(layer.id)
        lms[0].read.should be_true
        lms[0].write.should be_false
      end
    end

    context "when access to layer already exists" do
      it "grants read access and denies write access" do
        LayerMembership.create! :layer_id => layer.id, :membership => membership2, :read => false, :write => true

        membership2.set_layer_access :verb => :read, :access => true, :layer_id => layer.id

        lms = LayerMembership.all
        lms.length.should eq(1)
        lms[0].layer_id.should eq(layer.id)
        lms[0].membership_id.should eq(membership2.id)
        lms[0].read.should be_true
        lms[0].write.should be_false
      end

      it "revokes read access" do
        LayerMembership.create! :layer_id => layer.id, :membership => membership2, :read => true, :write => false

        membership2.set_layer_access :verb => :read, :access => false, :layer_id => layer.id

        LayerMembership.exists?.should be_false
      end
    end
  end

  context "on destroy" do
    it "destroys collection layer memberships" do

      membership.layer_memberships.create! :layer_id => layer.id, :read => true, :write => true

      membership.destroy

      collection.memberships.exists?.should be_false
      layer.layer_memberships.exists?.should be_false
    end
  end
end
