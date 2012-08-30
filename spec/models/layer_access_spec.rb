require 'spec_helper'

describe "layer access" do
  let!(:collection) { Collection.make }
  let!(:user) { User.make }
  let!(:membership) { Membership.create! user_id: user.id, collection_id: collection.id }
  let!(:layer1) { collection.layers.make }
  let!(:field1) { layer1.fields.make collection_id: collection.id }
  let!(:layer2) { collection.layers.make }
  let!(:field2) { layer2.fields.make collection_id: collection.id }

  context "fields for user" do
    it "only returns fields that can be read" do
      membership.set_layer_access :verb => :read, :access => true, :layer_id => layer1.id

      layers = collection.visible_fields_for user
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

      layers = collection.visible_fields_for user
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

  context "can write field" do
    it "can't write if property doesn't exist" do
      user.can_write_field?(collection, "unexistent").should be_false
    end

    it "can't write if only read access" do
      membership.set_layer_access :verb => :read, :access => true, :layer_id => layer1.id

      user.can_write_field?(collection, field1.es_code).should be_false
    end

    it "can write if write access" do
      membership.set_layer_access :verb => :write, :access => true, :layer_id => layer1.id

      user.can_write_field?(collection, field1.es_code).should be_true
    end

    it "can write if admin" do
      membership.admin = true
      membership.save!

      user.can_write_field?(collection, field1.es_code).should be_true
    end
  end
end
