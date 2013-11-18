require 'spec_helper'

describe CollectionsController do
  include Devise::TestHelpers
  render_views
  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make public: false) }

  before(:each) {sign_in user}

  it "should not throw error when calling unload_current_snapshot and no snapshot is set" do
    post :unload_current_snapshot, collection_id: collection.id
    assert_nil flash[:notice]
    assert_redirected_to collection_url(collection.id)
  end

  # Issue #627
  it "should not get public repeated one time for each membership" do
    collection.public = true
    collection.save

    user2 = collection.users.make email: 'user2@email.com'
    collection.memberships.create! user_id: user2.id

    get :index, format: 'json'
    collections =  JSON.parse response.body
    collections.count.should eq(1)
  end

  it "should get public collection being a guest user" do
    collection.public = true
    collection.save

    sign_out user

    get :show, format: 'json', id: collection.id
    response.should be_success
    json = JSON.parse response.body
    json["name"].should eq(collection.name)
  end

  # Issue #629
  it "should not get public collections in the index if the user is logged in" do
    # load collection
    collection

    other_collection = Collection.make public: true
    user2 = other_collection.users.make email: 'user2@email.com'
    other_collection.memberships.create! user_id: user2.id

    get :index, format: 'json'
    collections =  JSON.parse response.body
    collections.count.should eq(1)
  end

  it "admin should be able to update all collection's fields" do
    put :update, id: collection.id, collection: {"name"=>"new name", "description"=>"new description", "public"=>"1", "icon"=>"default"}
    response.should be_redirect

    updated_collection = Collection.find_by_name "new name"
    updated_collection.should be
    updated_collection.description.should eq("new description")
    updated_collection.public.should be_true
    updated_collection.icon.should eq("default")
  end

  describe "get ES resutls" do
      before(:each) do
        layer = collection.layers.make

        text = layer.text_fields.make :code => 'text'
        numeric = layer.numeric_fields.make :code => 'numeric'

        @site1 = collection.sites.make :name => "site1", :properties => {text.es_code => 'foo', numeric.es_code => 1 }
        @site2 = collection.sites.make :name => "osite2", :properties => {text.es_code => 'bar', numeric.es_code => 2 }
      end

    it "should get json of all field names and codes in a collection" do
      get :sites_by_term, collection_id: collection.id, format: 'json'

      json = JSON.parse response.body
      json.length.should eq(2)
      json[0]["id"].should eq(@site2.id)
      json[0]["name"].should eq(@site2.name)
      json[0]["value"].should eq(@site2.name)
      json[1]["id"].should eq(@site1.id)
      json[1]["name"].should eq(@site1.name)
      json[1]["value"].should eq(@site1.name)
    end

    it "should filter by name in a collection" do
      get :sites_by_term, collection_id: collection.id, format: 'json', term: "o"

      json = JSON.parse response.body
      json.length.should eq(1)
      json[0]["id"].should eq(@site2.id)
      json[0]["name"].should eq(@site2.name)
      json[0]["value"].should eq(@site2.name)
    end
  end

  describe "Permissions" do
    let(:public_collection) { user.create_collection(Collection.make public: true) }
    let(:not_member) { User.make }
    let(:member) { User.make }


    before(:each) do
      sign_out user
      collection.memberships.create! :user_id => member.id, admin: false
      public_collection.memberships.create! :user_id => member.id, admin: false
    end

    it 'should return forbidden in delete if user tries to delete a collection of which he is not member'  do
      sign_in not_member
      delete :destroy, id: collection.id
      response.status.should eq(403)
      delete :destroy, id: public_collection.id
      response.status.should eq(403)
    end

    it 'should return forbidden on delete if user is not collection admin' do
      sign_in member
      delete :destroy, id: collection.id
      response.status.should eq(403)
      delete :destroy, id: public_collection.id
      response.status.should eq(403)
    end

    it 'should return forbidden on create_snapshot if user is not collection admin' do
      sign_in member
      post :create_snapshot, collection_id: public_collection.id, snapshot: {name: 'my snapshot'}
      response.status.should eq(403)
      post :create_snapshot, collection_id: collection.id, snapshot: {name: 'my snapshot'}
      response.status.should eq(403)
    end

  end

  describe "analytic" do
    it 'should changed user.collection_count by 1' do
      expect{
        post :create, collection: { name: 'collection_1', icon: 'default'}
      }.to change{
        u = User.find user
        u.collection_count
      }.from(0).to(1)

    end
  end

  describe "public access" do
    let(:public_collection) { user.create_collection(Collection.make public: true) }
    before(:each) { sign_out :user }

    it 'should get index as guest' do
      get :index, collection_id: public_collection.id
      response.should be_success
    end

    it 'should not get index if collection_id is not passed' do
      get :index
      response.should_not be_success
    end

    it "should get current_user_membership for public collection" do
      get :current_user_membership, collection_id: public_collection.id, format: 'json'
      response.should be_success
      dummy_membership = JSON.parse response.body
      dummy_membership["admin"].should eq(false)
      dummy_membership["name"].should eq("read")
      dummy_membership["location"].should eq("read")
    end
  end

  describe "Permissions" do

    it "should get current_user_membership" do
      get :current_user_membership, collection_id: collection.id, format: 'json'
      response.should be_success
      membership = JSON.parse response.body
      membership["admin"].should eq(true)
      membership["name"].should eq("update")
      membership["location"].should eq("update")
    end
  end

  describe "sites info"  do
    it "gets when all have location" do
      collection.sites.make
      collection.sites.make

      get :sites_info, collection_id: collection.id

      info = JSON.parse response.body
      info["total"].should eq(2)
      info["no_location"].should be_false
    end

    it "gets when some have no location" do
      collection.sites.make
      collection.sites.make
      collection.sites.make lat: nil, lng: nil

      get :sites_info, collection_id: collection.id

      info = JSON.parse response.body
      info["total"].should eq(3)
      info["no_location"].should be_true
    end
  end

end
