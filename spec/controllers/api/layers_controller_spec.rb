require 'spec_helper'

describe Api::LayersController do
  include Devise::TestHelpers
  render_views

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make) }
  let!(:layer) {Layer.make collection: collection, user: user}
  let!(:layer2) {Layer.make collection: collection, user: user}


  context "as admin" do
    before(:each) {sign_in user}

    it "should get layers for a collection at present" do
      get :index, id: collection.id
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
      get :index, id: collection.id
      json = JSON.parse response.body

      json.length.should eq(2)
      json[0]['id'].should eq(layer.id)
      json[1]['id'].should eq(layer2.id)
    end

    it "should create a layer" do
      post :create, id: collection.id, layer: { name: 'layer_01', fields_attributes: {"0" => {name: "Numeric field", code: "numeric_field", kind: "numeric", ord: 1}}, ord: 1}
      collection.layers.count.should eq(3)
      collection.layers.map(&:name).should include("layer_01")
    end
  end

  context "as non authorized user" do
    let(:non_admin) { User.make }

    before(:each) { sign_in non_admin }

    it "should not get layers" do
      get :index, id: collection.id
      json = JSON.parse response.body

      json.should be_empty
    end

    it "should get layer if specifically authorized" do
      Membership.check_and_create(non_admin.email, collection.id)
      collection.memberships.count.should eq(2)
      membership = collection.memberships.find_by_user_id non_admin.id
      membership.set_layer_access({verb: 'read', access: true, layer_id: layer.id})
      get :index, id: collection.id
      json = JSON.parse response.body
      json.count.should eq(1)
      json.first["id"].should eq(layer.id)
    end
  end

end
