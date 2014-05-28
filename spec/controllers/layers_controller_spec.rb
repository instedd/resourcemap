require 'spec_helper'

describe LayersController do
  include Devise::TestHelpers
  render_views

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make) }
  let!(:layer) {Layer.make collection: collection, user: user}
  let!(:layer2) {Layer.make collection: collection, user: user}
  let!(:numeric) {layer.numeric_fields.make }

  before(:each) {sign_in user}

  describe "Backwards Compatibility" do
    it "should ignore layer updates with public param" do
      json_layer = {id: layer.id, name: layer.name, ord: layer.ord, anonymous_user_permission: 'none', public: 'public', fields_attributes: {:"0" => {code: numeric.code, id: numeric.id, kind: numeric.kind, name: numeric.name, ord: numeric.ord, layer_id: layer2.id}}}

      post :update, {layer: json_layer, collection_id: collection.id, id: layer.id}

      response.should be_success
    end
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

  describe 'analytic' do
    it 'should changed user.layer_count by 1' do
      expect {
        post :create, layer: { name: 'layer_01', fields: [], ord: 1}, collection_id: collection.id
      }.to change{
        u = User.find user
        u.layer_count
      }.from(0).to(1)
    end
  end

  it "shoud set order" do
    post :set_order, {ord: 2, collection_id: collection.id, id: layer.id}
    response.should be_success
    layer.reload
    layer.ord.should eq(2)
  end

  describe 'permissions' do
    let!(:not_a_user_collection) { Collection.make }
    let!(:member) { User.make email: 'foo@bar.com' }
    let!(:membership) { Membership.make collection: collection, user: member, admin: false }

    it 'should let any member list layers, but should hide layers without explicit read permissions' do
      sign_in member

      get :index, collection_id: collection.id, format: 'json'

      json = JSON.parse response.body
      json.length.should eq(0)
    end

    it 'should let admins see all layers' do
      get :index, collection_id: collection.id, format: 'json'

      json = JSON.parse response.body
      json.length.should eq(2)
    end

    it 'should let a member see a layer when there is an explicit layer membership with read=true' do
      LayerMembership.make layer: layer, membership: membership, read: true
      sign_in member

      get :index, collection_id: collection.id, format: 'json'
      json = JSON.parse response.body

      json.length.should eq(1)
      json[0]['id'].should eq(layer.id)
    end
  end
end
