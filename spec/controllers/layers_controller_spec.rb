require 'spec_helper'

describe LayersController do
  include Devise::TestHelpers
  render_views

  let!(:user) { User.make }
  let!(:collection) { user.create_collection(Collection.make) }
  let!(:layer) {Layer.make collection: collection, user: user}
  let!(:layer2) {Layer.make collection: collection, user: user}
  let!(:numeric) {Field.make layer: layer, collection: layer.collection, kind: "numeric"}

  before(:each) {sign_in user}

  it "should update field.layer_id" do

    layer.fields.count.should eq(1)
    json_layer = {id: layer.id, name: layer.name, ord: layer.ord, public: layer.public, fields_attributes: {:"0" => {code: numeric.code, id: numeric.id, kind: numeric.kind, name: numeric.name, ord: numeric.ord, layer_id: layer2.id}}}

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

end
