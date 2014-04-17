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
    collection.layers.last.destroy
    user_snapshot = UserSnapshot.for(user, collection)
    user_snapshot.go_to!('last_hour')
    get :index, id: collection.id
    json = JSON.parse response.body

    json.length.should eq(2)
    json[0]['id'].should eq(layer.id)
    json[1]['id'].should eq(layer2.id)
  end
end
