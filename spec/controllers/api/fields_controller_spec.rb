require 'spec_helper'

def get_layer(json, id)
  json.select{|l| l["id"] == id}.first
end

describe Api::FieldsController do
  include Devise::TestHelpers

  let(:admin) { User.make }

  let(:collection) { admin.create_collection(Collection.make) }
  let!(:layer) {Layer.make collection: collection, user: admin}
  let!(:layer2) {Layer.make collection: collection, user: admin}
  let!(:numeric) {layer.numeric_fields.make }

  let(:fields) do
    [
      {"name" => "Field 1", "code" => "fcode1", "kind" => "text"},
      {"name" => "Field 2", "code" => "fcode2", "kind" => "text"},
      {"name" => "Field 3", "code" => "fcode3", "kind" => "text"}
    ]
  end

  let(:member_who_writes) do 
    r = User.make 
    
    collection.memberships.create!({user_id: r.id})
    
    collection.memberships
      .find_by_user_id(r.id)
      .set_layer_access(layer_id: layer.id, verb: 'write', access: true)

    r
  end

  let(:member_who_reads) do
    r = User.make

    collection.memberships.create!({user_id: r.id})

    m = collection.memberships.find_by_user_id(r.id)
    m.set_layer_access(layer_id: layer.id, verb: 'read', access: true)

    r
  end

  shared_examples "user without permissions" do
    it "should not be allowed" do
      sign_in user

      post :create, collection_id: collection.id, layer_id: layer.id, fields: fields

      assert_response 403
    end
  end

  context "create" do
    describe "admin" do
      before(:each) { sign_in admin }

      it "should be allowed" do
        post :create, collection_id: collection.id, layer_id: layer.id, fields: fields

        assert_response :success

        get :index, collection_id: collection.id

        json = JSON.parse response.body
        layer_json = get_layer json, layer.id

        fields.each do |f|
          layer_json["fields"]
            .map{|x| x["code"]}
            .include?(f["code"]).should be_true
        end
      end

      it "should return abort the transaction and return CONFLICT if any of the fields already existed" do

        f = fields.push({ "name" => "Whatever", "code" => numeric.code, "kind" => "text" })

        post :create, collection_id: collection.id, layer_id: layer.id, fields: f

        assert_response 409

        get :index, collection_id: collection.id

        json = JSON.parse response.body
        layer_json = get_layer json, layer.id
        layer_json["fields"].length.should == 1
        layer_json["fields"][0]["code"].should == numeric.code
        layer_json["fields"][0]["name"].should == numeric.name
        layer_json["fields"][0]["kind"].should == numeric.kind
      end
    end

    describe "member with write access" do
      it_should_behave_like "user without permissions" do
        let(:user) { member_who_writes }
      end
    end

    describe "member with read access" do
      it_should_behave_like "user without permissions" do
        let(:user) { member_who_reads }
      end
    end
  end
end