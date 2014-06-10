require 'spec_helper'

describe Api::LayersController do
  include Devise::TestHelpers
  render_views

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make) }
  let!(:layer) {Layer.make collection: collection, user: user}
  let!(:layer2) {Layer.make collection: collection, user: user}
  let!(:numeric) {layer.numeric_fields.make }

  before(:each) {sign_in user}

  context "as admin" do
    it "should get layers for a collection at present" do
      get :index, collection_id: collection.id
      json = JSON.parse response.body

      json.length.should eq(2)
      json[0]['id'].should eq(layer.id)
      json[1]['id'].should eq(layer2.id)
    end

    it "should get layers for a snapshot" do
      snapshot = collection.snapshots.create! date: Time.now, name: 'last_hour'
      sleep 1
      collection.layers.last.destroy
      user_snapshot = UserSnapshot.for(user, collection)
      user_snapshot.go_to!('last_hour')
      get :index, collection_id: collection.id
      json = JSON.parse response.body

      json.length.should eq(2)
      json[0]['id'].should eq(layer.id)
      json[1]['id'].should eq(layer2.id)
    end

    it "should create a layer" do
      post :create, collection_id: collection.id, layer: { name: 'layer_01', fields_attributes: {"0" => {name: "Numeric field", code: "numeric_field", kind: "numeric", ord: 1}}, ord: 1}
      collection.layers.count.should eq(3)
      collection.layers.map(&:name).should include("layer_01")
    end

    it "should update field.layer_id" do
      layer.fields.count.should eq(1)
      json_layer = {id: layer.id, name: layer.name, ord: layer.ord, anonymous_user_permission: 'none', fields_attributes: {:"0" => {code: numeric.code, id: numeric.id, kind: numeric.kind, name: numeric.name, ord: numeric.ord, layer_id: layer2.id}}}

      post :update, {layer: json_layer, collection_id: collection.id, id: layer.id}

      layer.fields.count.should eq(0)
      layer2.fields.count.should eq(1)
      layer2.fields.first.name.should eq(numeric.name)

      histories = FieldHistory.where :field_id => numeric.id

      histories.count.should eq(2)

      histories.first.layer_id.should eq(layer.id)
      histories.first.valid_to.should_not be_nil

      histories.last.valid_to.should be_nil
      histories.last.layer_id.should eq(layer2.id)
    end

    it "should update a layer's fields" do
      json_layer = {id: layer.id, name: layer.name, ord: layer.ord, anonymous_user_permission: 'none', fields_attributes: {:"0" => {code: numeric.code, id: numeric.id, kind: numeric.kind, name: "New name", ord: numeric.ord}}}

      post :update, {layer: json_layer, collection_id: collection.id, id: layer.id}

      response.should be_success
      layer.fields.count.should eq(1)
      layer.fields.first.name.should eq("New name")
    end

    it "should delete a layer" do
      collection.layers.count.should eq(2)
      delete :destroy, collection_id: collection.id, id: layer.id
      response.should be_ok
      collection.layers.count.should eq(1)
    end
  end

  context "as non authorized user" do
    let(:non_admin) { User.make }

    before(:each) { sign_out user; sign_in non_admin }

    it "should not get layers" do
      get :index, collection_id: collection.id
      json = JSON.parse response.body

      json.should be_empty
    end

    it "should get layer if specifically authorized" do
      Membership.check_and_create(non_admin.email, collection.id)
      collection.memberships.count.should eq(2)
      membership = collection.memberships.find_by_user_id non_admin.id
      membership.set_layer_access({verb: 'read', access: true, layer_id: layer.id})
      get :index, collection_id: collection.id
      json = JSON.parse response.body
      json.count.should eq(1)
      json.first["id"].should eq(layer.id)
    end

    it "should not delete layers" do
      delete :destroy, collection_id: collection.id, id: layer.id
      response.status.should eq(403)
    end

    it "should not update layers" do
      json_layer = {id: layer.id, name: layer.name, ord: layer.ord, anonymous_user_permission: 'none', fields_attributes: {:"0" => {code: numeric.code, id: numeric.id, kind: numeric.kind, name: "New name", ord: numeric.ord}}}

      post :update, {layer: json_layer, collection_id: collection.id, id: layer.id}
      response.should be_forbidden
    end

  end

  describe "Backwards Compatibility" do
    it "should ignore layer updates with public param" do
      json_layer = {id: layer.id, name: layer.name, ord: layer.ord, anonymous_user_permission: 'none', public: 'public', fields_attributes: {:"0" => {code: numeric.code, id: numeric.id, kind: numeric.kind, name: numeric.name, ord: numeric.ord, layer_id: layer2.id}}}

      post :update, {layer: json_layer, collection_id: collection.id, id: layer.id}

      response.should be_success
    end
  end



end
