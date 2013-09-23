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
end
