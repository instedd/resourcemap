require 'spec_helper'

describe "layer access" do
  auth_scope(:user) { User.make }
  let!(:collection) { user.create_collection Collection.make_unsaved }
  let(:user2) { AuthCop.unsafe { User.make } }
  let!(:membership) { Membership.create! user_id: user2.id, collection_id: collection.id }
  let!(:layer1) { collection.layers.make }
  let!(:field1) { layer1.text_fields.make collection_id: collection.id }
  let!(:layer2) { collection.layers.make }
  let!(:field2) { layer2.text_fields.make collection_id: collection.id }
  let!(:site) { collection.sites.make }

  context "fields for user" do
    it "only returns fields that can be read" do
      membership.set_layer_access :verb => :read, :access => true, :layer_id => layer1.id
      membership.set_layer_access :verb => :read, :access => false, :layer_id => layer2.id

      AuthCop.with_auth_scope(user2) do
        layers = collection.visible_layers_for user2
        layers.length.should eq(1)
        layers[0][:name].should eq(layer1.name)

        fields = layers[0][:fields]
        fields.length.should eq(1)
        fields[0][:id].should eq(field1.es_code)
        fields[0][:writeable].should be_false
      end
    end

    it "returns all fields if admin" do
      layers = collection.visible_layers_for user
      layers.length.should eq(2)
      layers[0][:name].should eq(layer1.name)
      layers[1][:name].should eq(layer2.name)

      fields = layers[0][:fields]
      fields.length.should eq(1)
      fields[0][:id].should eq(field1.es_code)
      fields[0][:writeable].should be_true

      fields = layers[1][:fields]
      fields.length.should eq(1)
      fields[0][:id].should eq(field2.es_code)
      fields[0][:writeable].should be_true
    end
  end

  describe "guest user" do
    let(:guest_user) { AuthCop.unsafe { GuestUser.new } }
    let(:collection2) { user.create_collection Collection.make_unsaved(anonymous_name_permission: 'read', anonymous_location_permission: 'read') }
    let(:l1) { collection2.layers.make(anonymous_user_permission: 'read') }
    let(:l2) { collection2.layers.make}

    it "can read if layer has read permission for anonymous" do
      guest_user.policy(l1).read?.should be_true
    end

    it "can't read if collection hasn't got read permission for anonymous" do
      guest_user.policy(l2).read?.should be_false
    end

    it "is not able to update layers" do
      guest_user.policy(l1).update?.should be_false
      guest_user.policy(l2).update?.should be_false
    end
  end

  describe "snapshots" do

    it "should return layers form snapshot" do

      stub_time '2011-01-01 10:00:00 -0500'
      new_layer = collection.layers.make
      new_field = new_layer.text_fields.make collection_id: collection.id

      stub_time '2011-01-01 11:00:00 -0500'
      new_field.name = "new name"

      snapshot = Snapshot.make collection: collection, date: '2011-01-01 12:00:00 -0500'
      user_snapshot = UserSnapshot.make user: user, snapshot: snapshot

      new_field.name = "other name"

      membership.set_layer_access :verb => :read, :access => true, :layer_id => new_layer.id
      membership.set_layer_access :verb => :read, :access => false, :layer_id => layer2.id

      layers = collection.visible_layers_for(user, {snapshot_id: snapshot.id})
      layers.length.should eq(1)
      layers[0][:name].should eq(new_layer.name)

    end
  end

  context "can write field" do
    it "can't write if property doesn't exist" do
      user_ability = Ability.new user

      (user_ability.can? :update_site_property, nil, site).should be_false
    end

    it "can't write if only read access" do
      membership.set_layer_access :verb => :read, :access => true, :layer_id => layer1.id
      user_ability = Ability.new user

      (user_ability.can? :update_site_property, field1, site).should be_false
    end

    it "can write if write access" do
      membership.set_layer_access :verb => :write, :access => true, :layer_id => layer1.id
      user_ability = Ability.new user

      (user_ability.can? :update_site_property, field1, site).should be_true
    end

    it "can write if admin" do
      membership.admin = true
      membership.save!
      user_ability = Ability.new user

      (user_ability.can? :update_site_property, field1, site).should be_true
    end
  end

end
