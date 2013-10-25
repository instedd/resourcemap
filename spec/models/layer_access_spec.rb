require 'spec_helper'

describe "layer access" do
  let!(:collection) { Collection.make }
  let!(:user) { User.make }
  let!(:membership) { Membership.create! user_id: user.id, collection_id: collection.id }
  let!(:layer1) { collection.layers.make }
  let!(:field1) { layer1.text_fields.make collection_id: collection.id }
  let!(:layer2) { collection.layers.make }
  let!(:field2) { layer2.text_fields.make collection_id: collection.id }
  let!(:site) { collection.sites.make }

  context "fields for user" do
    it "only returns fields that can be read" do
      membership.set_layer_access :verb => :read, :access => true, :layer_id => layer1.id
      membership.set_layer_access :verb => :read, :access => false, :layer_id => layer2.id

      layers = collection.visible_layers_for user
      layers.length.should eq(1)
      layers[0][:name].should eq(layer1.name)

      fields = layers[0][:fields]
      fields.length.should eq(1)
      fields[0][:id].should eq(field1.es_code)
      fields[0][:writeable].should be_false
    end

    it "returns all fields if admin" do
      membership.admin = true
      membership.save!

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
