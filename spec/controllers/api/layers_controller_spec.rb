require 'spec_helper'

describe Api::LayersController, :type => :controller do
  include Devise::TestHelpers
  render_views

  let(:user) { User.make! }
  let(:collection) { user.create_collection(Collection.make!) }
  let!(:layer) {Layer.make! collection: collection, user: user}
  let!(:layer2) {Layer.make! collection: collection, user: user}
  let!(:numeric) {layer.numeric_fields.make! }

  before(:each) {sign_in user}

  context "as admin" do
    it "should get layers for a collection at present" do
      get :index, collection_id: collection.id
      json = JSON.parse response.body

      expect(json.length).to eq(2)
      expect(json[0]['id']).to eq(layer.id)
      expect(json[1]['id']).to eq(layer2.id)
    end

    it "should get layers for a snapshot" do
      Timecop.travel(1.hour.from_now)
      snapshot = collection.snapshots.create! date: 1.hour.ago, name: 'last_hour'
      collection.layers.last.destroy
      user_snapshot = UserSnapshot.for(user, collection)
      success = user_snapshot.go_to!(snapshot.id)
      expect(success).to be_truthy
      get :index, collection_id: collection.id
      json = JSON.parse response.body

      expect(json.length).to eq(2)
      expect(json[0]['id']).to eq(layer.id)
      expect(json[1]['id']).to eq(layer2.id)
    end

    it "should create a layer" do
      post :create, collection_id: collection.id, layer: { name: 'layer_01', fields_attributes: {"0" => {name: "Numeric field", code: "numeric_field", kind: "numeric", ord: 1}}, ord: 1}
      expect(collection.layers.count).to eq(3)
      expect(collection.layers.map(&:name)).to include("layer_01")
    end

    it "should update field.layer_id" do
      expect(layer.fields.count).to eq(1)
      json_layer = {id: layer.id, name: layer.name, ord: layer.ord, anonymous_user_permission: 'none', fields_attributes: {:"0" => {code: numeric.code, id: numeric.id, kind: numeric.kind, name: numeric.name, ord: numeric.ord, layer_id: layer2.id}}}

      post :update, {layer: json_layer, collection_id: collection.id, id: layer.id}

      expect(layer.fields.count).to eq(0)
      expect(layer2.fields.count).to eq(1)
      expect(layer2.fields.first.name).to eq(numeric.name)

      histories = FieldHistory.where :field_id => numeric.id

      expect(histories.count).to eq(2)

      expect(histories.first.layer_id).to eq(layer.id)
      expect(histories.first.valid_to).not_to be_nil

      expect(histories.last.valid_to).to be_nil
      expect(histories.last.layer_id).to eq(layer2.id)
    end

    it "should update a layer's fields" do
      json_layer = {id: layer.id, name: layer.name, ord: layer.ord, anonymous_user_permission: 'none', fields_attributes: {:"0" => {code: numeric.code, id: numeric.id, kind: numeric.kind, name: "New name", ord: numeric.ord}}}

      post :update, {layer: json_layer, collection_id: collection.id, id: layer.id}

      expect(response).to be_success
      expect(layer.fields.count).to eq(1)
      expect(layer.fields.first.name).to eq("New name")
    end

    it "should delete a layer" do
      expect(collection.layers.count).to eq(2)
      delete :destroy, collection_id: collection.id, id: layer.id
      expect(response).to be_ok
      expect(collection.layers.count).to eq(1)
    end
  end

  context "as non authorized user" do
    let(:non_admin) { User.make! }

    before(:each) { sign_out user; sign_in non_admin }

    it "should not get layers" do
      get :index, collection_id: collection.id
      json = JSON.parse response.body

      expect(json).to be_empty
    end

    it "should get layer if specifically authorized" do
      Membership.check_and_create(non_admin.email, collection.id)
      expect(collection.memberships.count).to eq(2)
      membership = collection.memberships.find_by_user_id non_admin.id
      membership.set_layer_access({verb: 'read', access: true, layer_id: layer.id})
      get :index, collection_id: collection.id
      json = JSON.parse response.body
      expect(json.count).to eq(1)
      expect(json.first["id"]).to eq(layer.id)
    end

    it "should not delete layers" do
      delete :destroy, collection_id: collection.id, id: layer.id
      expect(response.status).to eq(403)
    end

    it "should not update layers" do
      json_layer = {id: layer.id, name: layer.name, ord: layer.ord, anonymous_user_permission: 'none', fields_attributes: {:"0" => {code: numeric.code, id: numeric.id, kind: numeric.kind, name: "New name", ord: numeric.ord}}}

      post :update, {layer: json_layer, collection_id: collection.id, id: layer.id}
      expect(response).to be_forbidden
    end

  end

  describe "Backwards Compatibility" do
    it "should ignore layer updates with public param" do
      json_layer = {id: layer.id, name: layer.name, ord: layer.ord, anonymous_user_permission: 'none', public: 'public', fields_attributes: {:"0" => {code: numeric.code, id: numeric.id, kind: numeric.kind, name: numeric.name, ord: numeric.ord, layer_id: layer2.id}}}

      post :update, {layer: json_layer, collection_id: collection.id, id: layer.id}

      expect(response).to be_success
    end
  end



end
