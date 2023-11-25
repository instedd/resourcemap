require 'spec_helper'

describe FieldsController, :type => :controller do
  include Devise::TestHelpers
  render_views

  let(:admin) { User.make }
  let(:collection) { admin.create_collection(Collection.make) }
  let(:layer) { collection.layers.make user: admin}
  config_hierarchy = [{ id: '60', name: 'Dad', type: 'region', sub: [{id: '100', name: 'Son', type: 'district'}, {id: '101', name: 'Bro', type: 'district'}]}]
  let!(:hierarchy) { layer.hierarchy_fields.make :code => 'hierarchy', config: { hierarchy: config_hierarchy }.with_indifferent_access }

  it "should get field in json" do
    sign_in admin

    get :show, params: { collection_id: collection.id, id: hierarchy.id, format: 'json' }

    json = JSON.parse response.body
    expect(json['kind']).to eq('hierarchy')
    expect(json['config']).to eq(
      {"hierarchy"=>
        [
          {"id"=>"60", "name"=>"Dad", "type" =>"region", "sub"=>[{"id"=>"100", "name"=>"Son", "type"=>"district"}, {"id"=>"101", "name"=>"Bro","type"=>"district"}]}
        ]
      }
    )
  end

  it "should not get field if the user is not admin" do
    member = User.make
    membership = Membership.make collection: collection, user: member, admin: false
    sign_in member

    get :show, params: { collection_id: collection.id, id: hierarchy.id, format: 'json' }

    expect(response.status).to eq(403)
  end

  it "should not get field mapping if not logged in and collection is public" do
    collection = admin.create_collection(Collection.make(anonymous_name_permission: 'read', anonymous_location_permission: 'read'))

    get :mapping, params: { collection_id: collection.id, format: 'json' }

    # Redirected to login
    expect(response.status).to eq(401)
  end

  it "should not get field in other collection" do
    sign_in admin
    collection2 = admin.create_collection(Collection.make)
    layer2 = collection2.layers.make
    text_field = layer2.text_fields.make code: 'text'

    get :show, params: { collection_id: collection.id, id: text_field.id, format: 'json' }

    expect(response.status).to eq(404)
  end

  it "should get mapping" do
    sign_in admin

    get :mapping, params: { collection_id: collection.id }
    json = JSON.parse response.body
    expect(json.length).to eq(1)
    field = json[0]
    expect(field["name"]).to eq(hierarchy.name)
    expect(field["id"]).to eq(hierarchy.id)
    expect(field["code"]).to eq('hierarchy')
    expect(field["kind"]).to eq('hierarchy')
  end

  it "should get hierarchy nodes under certain one" do
    sign_in admin

    get :hierarchy, params: { collection_id: collection.id, id: hierarchy.id, under: '60', format: 'json' }
    elements = JSON.parse response.body
    expect(elements.length).to eq 3
    expect(elements).to include('60')
    expect(elements).to include('100')
    expect(elements).to include('101')
  end

  it "should get error if the field is not a hierarchy" do
    sign_in admin

    text = layer.text_fields.make :code => 'text'

    get :hierarchy, params: { collection_id: collection.id, id: text.id, under: '60', format: 'json' }
    expect(response.status).to eq(422)
    message = (JSON.parse response.body)["message"]
    expect(message).to include("The field 'text' is not a hierarchy.")
  end

  it "should show proper error message if the under parameter is not found" do
    sign_in admin

    get :hierarchy, params: { collection_id: collection.id, id: hierarchy.id, under: 'invalid', format: 'json' }
    expect(response.status).to eq(422)
    message = (JSON.parse response.body)["message"]
    expect(message).to include("Invalid hierarchy option 'invalid' in field 'hierarchy'")
  end

  it "should show proper error message if the node parameter is not found" do
    sign_in admin

    get :hierarchy, params: { collection_id: collection.id, id: hierarchy.id, under: '60', node: 'invalid', format: 'json' }
    expect(response.status).to eq(422)
    message = (JSON.parse response.body)["message"]
    expect(message).to include("Invalid hierarchy option 'invalid' in field 'hierarchy'")
  end

  it "should respond true if a certain node is under another" do
    sign_in admin

    get :hierarchy, params: { collection_id: collection.id, id: hierarchy.id, under: '60', node: '100', format: 'json' }
    expect(response.body).to eq("true")
  end

  it "should respond false if a certain node is under another" do
    sign_in admin

    get :hierarchy, params: { collection_id: collection.id, id: hierarchy.id, under: '100', node: '60', format: 'json' }
    expect(response.body).to eq("false")
  end

  it "should get 403 if the user is not admin " do
    member = User.make
    membership = Membership.make collection: collection, user: member, admin: false
    sign_in member
    get :hierarchy, params: { collection_id: collection.id, id: hierarchy.id, under: '60', format: 'json' }
    expect(response.status).to eq(403)
  end

  it "should get hierarchy as CSV" do
    sign_in admin

    get :hierarchy, params: { collection_id: collection.id, id: hierarchy.id, format: 'csv' }
    expect(response.status).to eq(200)
    csv =  CSV.parse(response.body)
    expect(csv[0]).to eq(['ID', 'ParentID', 'ItemName'])
    expect(csv[1]).to eq(['60', '', 'Dad'])
    expect(csv[2]).to eq(['100', '60', 'Son'])
    expect(csv[3]).to eq(['101', '60', 'Bro'])
  end

  it "should not get hierarchy as CSV if the user is not admin" do
    member = User.make
    membership = Membership.make collection: collection, user: member, admin: false
    sign_in member
    get :hierarchy, params: { collection_id: collection.id, id: hierarchy.id, format: 'csv' }
    expect(response.status).to eq(403)
  end

  it "should get hierarchy by node and type" do
    sign_in admin

    get :hierarchy, params: { collection_id: collection.id, id: hierarchy.id, node: '100', type: 'region',format: 'json' }
    elements = JSON.parse response.body
    expect(elements).to eq({"id"=>"60", "name"=>"Dad", "type"=>"region"})
  end
end
