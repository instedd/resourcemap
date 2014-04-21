require 'spec_helper'

describe Api::LayersController do
  include Devise::TestHelpers
  render_views

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make) }
  let!(:layer) {Layer.make collection: collection, user: user}
  let!(:layer2) {Layer.make collection: collection, user: user}

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
