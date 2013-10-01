require 'spec_helper'

describe FieldsController do
  include Devise::TestHelpers
  render_views

  let(:admin) { User.make }
  let(:collection) { admin.create_collection(Collection.make) }
  let(:layer) { collection.layers.make user: admin}
  config_hierarchy = [{ id: '60', name: 'Dad', sub: [{id: '100', name: 'Son'}, {id: '101', name: 'Bro'}]}]
  let!(:hierarchy) { layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access }

  it "should get field in json" do
    sign_in admin

    get :show, collection_id: collection.id, id: hierarchy.id, format: 'json'

    json = JSON.parse response.body
    json['kind'].should eq('hierarchy')
    json['config'].should eq(
      {"hierarchy"=>
        [
          {"id"=>"60", "name"=>"Dad", "sub"=>[{"id"=>"100", "name"=>"Son"}, {"id"=>"101", "name"=>"Bro"}]}
        ]
      }
    )
  end

  it "should not get field if the user is not admin" do
    member = User.make
    membership = Membership.make collection: collection, user: member, admin: false
    sign_in member

    get :show, collection_id: collection.id, id: hierarchy.id, format: 'json'

    response.status.should eq(403)
  end

  it "should not get field in other collection" do
    sign_in admin
    collection2 = admin.create_collection(Collection.make)
    layer2 = collection2.layers.make
    text_field = layer2.text_fields.make code: 'text'

    get :show, collection_id: collection.id, id: text_field.id, format: 'json'

    response.status.should eq(404)
  end

  it "should get mapping" do
    sign_in admin

    get :mapping, collection_id: collection.id
    json = JSON.parse response.body
    json.length.should eq(1)
    field = json[0]
    field["name"].should eq(hierarchy.name)
    field["id"].should eq(hierarchy.id)
    field["code"].should eq('hierarchy')
    field["kind"].should eq('hierarchy')
  end

  it "should get hierarchy nodes under certain one" do
    sign_in admin

    get :hierarchy, collection_id: collection.id, id: hierarchy.id, under: '60'
    elements = JSON.parse response.body
    elements.length.should eq 3
    elements.should include('60')
    elements.should include('100')
    elements.should include('101')
  end

  it "should get error if the field is not a hierarchy" do
    sign_in admin

    text = layer.text_fields.make :code => 'text'

    get :hierarchy, collection_id: collection.id, id: text.id, under: '60'
    response.status.should eq(422)
    message = (JSON.parse response.body)["message"]
    message.should include("The field 'text' is not a hierarchy.")
  end


  it "should show proper error message if the under parameter is not found" do
    sign_in admin

    get :hierarchy, collection_id: collection.id, id: hierarchy.id, under: 'invalid'
    response.status.should eq(422)
    message = (JSON.parse response.body)["message"]
    message.should include("Invalid hierarchy option 'invalid' in field 'hierarchy'")
  end

  it "should show proper error message if the node parameter is not found" do
    sign_in admin

    get :hierarchy, collection_id: collection.id, id: hierarchy.id, under: '60', node: 'invalid'
    response.status.should eq(422)
    message = (JSON.parse response.body)["message"]
    message.should include("Invalid hierarchy option 'invalid' in field 'hierarchy'")
  end


  it "should responde if a certain node is under anotherone" do
    sign_in admin

    get :hierarchy, collection_id: collection.id, id: hierarchy.id, under: '60', node: '100'
    response.body.should eq("true")
  end

  it "should get 403 if the user is not admin " do
    member = User.make
    membership = Membership.make collection: collection, user: member, admin: false
    sign_in member
    get :hierarchy, collection_id: collection.id, id: hierarchy.id, under: '60'
    response.status.should eq(403)
  end
end
