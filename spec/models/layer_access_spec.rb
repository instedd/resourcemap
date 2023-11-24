require 'spec_helper'

describe "layer access", :type => :model do
  let!(:collection) { Collection.make! }
  let!(:user) { User.make! }
  let!(:membership) { Membership.create! user_id: user.id, collection_id: collection.id }
  let!(:layer1) { collection.layers.make! }
  let!(:field1) { layer1.text_fields.make! collection_id: collection.id }
  let!(:layer2) { collection.layers.make! }
  let!(:field2) { layer2.text_fields.make! collection_id: collection.id }
  let!(:site) { collection.sites.make! }

  context "fields for user" do
    it "only returns fields that can be read" do
      membership.set_layer_access :verb => :read, :access => true, :layer_id => layer1.id
      membership.set_layer_access :verb => :read, :access => false, :layer_id => layer2.id

      layers = collection.visible_layers_for user
      expect(layers.length).to eq(1)
      expect(layers[0][:name]).to eq(layer1.name)

      fields = layers[0][:fields]
      expect(fields.length).to eq(1)
      expect(fields[0][:id]).to eq(field1.es_code)
      expect(fields[0][:writeable]).to be_falsey
    end

    it "returns all fields if admin" do
      membership.admin = true
      membership.save!

      layers = collection.visible_layers_for user
      expect(layers.length).to eq(2)
      expect(layers[0][:name]).to eq(layer1.name)
      expect(layers[1][:name]).to eq(layer2.name)

      fields = layers[0][:fields]
      expect(fields.length).to eq(1)
      expect(fields[0][:id]).to eq(field1.es_code)
      expect(fields[0][:writeable]).to be_truthy

      fields = layers[1][:fields]
      expect(fields.length).to eq(1)
      expect(fields[0][:id]).to eq(field2.es_code)
      expect(fields[0][:writeable]).to be_truthy
    end
  end

  describe "guest user" do
    let!(:guest_user) { GuestUser.new }
    let!(:user_ability) {Ability.new guest_user}
    let!(:collection2) { Collection.make!(anonymous_name_permission: 'read', anonymous_location_permission: 'read') }
    let!(:l1) { collection2.layers.make!(anonymous_user_permission: 'read') }
    let!(:l2) { collection2.layers.make!}

    it "can read if layer has read permission for anonymous" do
      expect(user_ability.can? :read, l1).to be_truthy
    end

    it "can't read if collection hasn't got read permission for anonymous" do
      expect(user_ability.can? :read, l2).to be_falsey
    end

    it "is not able to update layers" do
      expect(user_ability.can? :update, l1, collection2).to be_falsey
      expect(user_ability.can? :update, l2, collection2).to be_falsey
    end
  end

  describe "snapshots" do

    it "should return layers form snapshot" do

      stub_time '2011-01-01 10:00:00 -0500'
      new_layer = collection.layers.make!
      new_field = new_layer.text_fields.make! collection_id: collection.id

      stub_time '2011-01-01 11:00:00 -0500'
      new_field.name = "new name"

      snapshot = Snapshot.make! collection: collection, date: '2011-01-01 12:00:00 -0500'
      user_snapshot = UserSnapshot.make! user: user, snapshot: snapshot

      new_field.name = "other name"

      membership.set_layer_access :verb => :read, :access => true, :layer_id => new_layer.id
      membership.set_layer_access :verb => :read, :access => false, :layer_id => layer2.id

      layers = collection.visible_layers_for(user, {snapshot_id: snapshot.id})
      expect(layers.length).to eq(1)
      expect(layers[0][:name]).to eq(new_layer.name)

    end
  end

  context "can write field" do
    it "can't write if property doesn't exist" do
      user_ability = Ability.new user

      expect(user_ability.can? :update_site_property, nil, site).to be_falsey
    end

    it "can't write if only read access" do
      membership.set_layer_access :verb => :read, :access => true, :layer_id => layer1.id
      user_ability = Ability.new user

      expect(user_ability.can? :update_site_property, field1, site).to be_falsey
    end

    it "can write if write access" do
      membership.set_layer_access :verb => :write, :access => true, :layer_id => layer1.id
      user_ability = Ability.new user

      expect(user_ability.can? :update_site_property, field1, site).to be_truthy
    end

    it "can write if admin" do
      membership.admin = true
      membership.save!
      user_ability = Ability.new user

      expect(user_ability.can? :update_site_property, field1, site).to be_truthy
    end
  end

end
