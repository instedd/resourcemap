require 'spec_helper'

describe LayersController, :type => :controller do
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

      post :update, params: {layer: json_layer, collection_id: collection.id, id: layer.id}

      expect(response).to be_success
    end
  end

  it "should update field.layer_id" do
    expect(layer.fields.count).to eq(1)
    json_layer = {id: layer.id, name: layer.name, ord: layer.ord, anonymous_user_permission: 'none', fields_attributes: {:"0" => {code: numeric.code, id: numeric.id, kind: numeric.kind, name: numeric.name, ord: numeric.ord, layer_id: layer2.id}}}

    post :update, params: {layer: json_layer, collection_id: collection.id, id: layer.id}

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

    post :update, params: {layer: json_layer, collection_id: collection.id, id: layer.id}

    expect(response).to be_success
    expect(layer.fields.count).to eq(1)
    expect(layer.fields.first.name).to eq("New name")
  end

  describe 'analytic' do
    it 'should changed user.layer_count by 1' do
      expect {
        post :create, params: { layer: { name: 'layer_01', fields: [], ord: 1}, collection_id: collection.id }
      }.to change{
        u = User.find user.id
        u.layer_count
      }.from(0).to(1)
    end
  end

  it "shoud set order" do
    post :set_order, params: {ord: 2, collection_id: collection.id, id: layer.id}
    expect(response).to be_success
    layer.reload
    expect(layer.ord).to eq(2)
  end

  describe 'permissions' do
    let!(:not_a_user_collection) { Collection.make }
    let!(:member) { User.make email: 'foo@bar.com' }
    let!(:membership) { Membership.make collection: collection, user: member, admin: false }

    it 'should let any member list layers, but should hide layers without explicit read permissions' do
      sign_in member

      get :index, params: { collection_id: collection.id, format: 'json' }

      json = JSON.parse response.body
      expect(json.length).to eq(0)
    end

    it 'should let admins see all layers' do
      get :index, params: { collection_id: collection.id, format: 'json' }

      json = JSON.parse response.body
      expect(json.length).to eq(2)
    end

    it 'should let a member see a layer when there is an explicit layer membership with read=true' do
      LayerMembership.make layer: layer, membership: membership, read: true
      sign_in member

      get :index, params: { collection_id: collection.id, format: 'json' }
      json = JSON.parse response.body

      expect(json.length).to eq(1)
      expect(json[0]['id']).to eq(layer.id)
    end

    it 'should let an admin set order' do
      sign_in user
      post :order, params: {order: [layer2.id, layer.id], collection_id: collection.id}

      layer.reload
      layer2.reload

      expect(response).to be_success
      expect(layer.ord).to eq(2)
      expect(layer2.ord).to eq(1)
    end

    let!(:not_member) { User.make email: 'foo2@bar.com' }

    it "shouldn't let member set order" do
      sign_in member

      post :order, params: {order: [layer2.id, layer.id], collection_id: collection.id}

      layer.reload
      layer2.reload

      expect(response.status).to eq(403)
      expect(layer.ord).to eq(1)
      expect(layer2.ord).to eq(2)
    end
  end
end
