require 'spec_helper'

describe CollectionsController, :type => :controller do
  include Devise::TestHelpers
  render_views
  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make(anonymous_name_permission: 'read', anonymous_location_permission: 'read'))}

  before(:each) {sign_in user}

  def make_private(collection)
    collection.anonymous_location_permission = nil
    collection.anonymous_name_permission = nil
    collection.save
  end

  def make_public(collection)
    collection.anonymous_location_permission = 'read'
    collection.anonymous_name_permission = 'read'
    collection.save
  end

  it "should not throw error when calling unload_current_snapshot and no snapshot is set" do
    post :unload_current_snapshot, collection_id: collection.id
    assert_nil flash[:notice]
    assert_redirected_to collection_url(collection.id)
  end

  # Issue #627
  it "should not get public repeated one time for each membership" do
    make_public(collection)

    user2 = collection.users.make email: 'user2@email.com'
    collection.memberships.create! user_id: user2.id

    get :index, format: 'json'
    collections =  JSON.parse response.body
    expect(collections.count).to eq(1)
  end

  # Issue #629
  it "should not get public collections in the index if the user is logged in" do
    # load collection
    collection

    other_collection = Collection.make(anonymous_name_permission: 'read', anonymous_location_permission: 'read')
    user2 = other_collection.users.make email: 'user2@email.com'
    other_collection.memberships.create! user_id: user2.id

    get :index, format: 'json'
    collections =  JSON.parse response.body
    expect(collections.count).to eq(1)
  end

  it "admin should be able to update all collection's fields" do
    put :update, id: collection.id, collection: {"name"=>"new name", "description"=>"new description", "icon"=>"default"}
    expect(response).to be_redirect

    updated_collection = Collection.find_by_name "new name"
    expect(updated_collection).to be
    expect(updated_collection.description).to eq("new description")
    expect(updated_collection.icon).to eq("default")
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
      expect(json.length).to eq(2)
      expect(json[0]["id"]).to eq(@site2.id)
      expect(json[0]["name"]).to eq(@site2.name)
      expect(json[0]["value"]).to eq(@site2.name)
      expect(json[1]["id"]).to eq(@site1.id)
      expect(json[1]["name"]).to eq(@site1.name)
      expect(json[1]["value"]).to eq(@site1.name)
    end

    it "should filter by name in a collection" do
      get :sites_by_term, collection_id: collection.id, format: 'json', term: "o"

      json = JSON.parse response.body
      expect(json.length).to eq(1)
      expect(json[0]["id"]).to eq(@site2.id)
      expect(json[0]["name"]).to eq(@site2.name)
      expect(json[0]["value"]).to eq(@site2.name)
    end
  end

  describe "Permissions" do
    let(:public_collection) { user.create_collection(Collection.make(anonymous_name_permission: 'read', anonymous_location_permission: 'read')) }
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
      expect(response.status).to eq(403)
      delete :destroy, id: public_collection.id
      expect(response.status).to eq(403)
    end

    it 'should return forbidden on delete if user is not collection admin' do
      sign_in member
      delete :destroy, id: collection.id
      expect(response.status).to eq(403)
      delete :destroy, id: public_collection.id
      expect(response.status).to eq(403)
    end

    it 'should return forbidden on create_snapshot if user is not collection admin' do
      sign_in member
      post :create_snapshot, collection_id: public_collection.id, snapshot: {name: 'my snapshot'}
      expect(response.status).to eq(403)
      post :create_snapshot, collection_id: collection.id, snapshot: {name: 'my snapshot'}
      expect(response.status).to eq(403)
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

  describe "Permissions" do
    describe "guest user" do
      before(:each) { sign_out :user }

      def expect_redirect_to_login(response)
        expect(response.status).to eq(302)
        expect(response.location).to eq(new_user_session_url)
      end

      # This is a regression test to ensure this leak
      # doesn't get back: https://github.com/instedd/resourcemap/blob/26d529aa457bd16e408fe99e6496853d63b7f806/app/controllers/collections_controller.rb#L24
      it "should redirect guest user to log in if she tries to list search collections by name" do
        collection.name = "Foo"
        make_private collection

        get :index, name: "Foo"
        expect_redirect_to_login(response)
      end

      it "should redirect guest user to log in if she tries to access a non-public collection" do
        make_private collection
        get :index, collection_id: collection.id
        expect_redirect_to_login(response)
      end

      it "should allow guest user to read public collection" do
        make_public collection
        get :index, collection_id: collection.id
        expect(response.status).to eq(200)
      end

      it "should get public collection being a guest user" do
        make_public(collection)
        get :show, format: 'json', id: collection.id
        expect(response).to be_success
        json = JSON.parse response.body
        expect(json["name"]).to eq(collection.name)
      end

      # Issue #661
      it "should not get public collection's settings page being a guest user" do
        make_public(collection)
        get :show, format: 'html', id: collection.id
        expect(response).to redirect_to '/users/sign_in'
      end
    end

    it "should get current_user_membership" do
      get :current_user_membership, collection_id: collection.id, format: 'json'
      expect(response).to be_success
      membership = JSON.parse response.body
      expect(membership["admin"]).to eq(true)
      expect(membership["name"]).to eq("update")
      expect(membership["location"]).to eq("update")
    end
  end

  describe "sites info"  do
    it "gets when all have location" do
      collection.sites.make
      collection.sites.make

      get :sites_info, collection_id: collection.id

      info = JSON.parse response.body
      expect(info["total"]).to eq(2)
      expect(info["no_location"]).to be_falsey
    end

    it "gets when some have no location" do
      collection.sites.make
      collection.sites.make
      collection.sites.make lat: nil, lng: nil

      get :sites_info, collection_id: collection.id

      info = JSON.parse response.body
      expect(info["total"]).to eq(3)
      expect(info["no_location"]).to be_truthy
    end

    describe "when there are deleted sites" do
      it "gets when all have location" do
        collection.sites.make
        collection.sites.make.destroy

        get :sites_info, collection_id: collection.id

        info = JSON.parse response.body
        expect(info["total"]).to eq(1)
        expect(info["no_location"]).to be_falsey
      end
    end

    it "gets when some have no location" do
      collection.sites.make
      collection.sites.make
      collection.sites.make(lat: nil, lng: nil).destroy

      get :sites_info, collection_id: collection.id

      info = JSON.parse response.body
      expect(info["total"]).to eq(2)
      expect(info["no_location"]).to be_falsey
    end
  end

  it "should ignore local param in search" do
    get :search, collection_id: collection.id
    expect(response).to be_ok
  end

  it "gets a site with location when the lat is 0, and the lng is 0 in search" do
    collection.sites.make lat: 0, lng: 0

    get :search, collection_id: collection.id

    result = JSON.parse response.body
    sites = result["sites"]

    expect(sites.first).to include("lat")
    expect(sites.first).to include("lng")
    expect(sites.first["lat"]).to eq(0)
    expect(sites.first["lng"]).to eq(0)
  end

  it "gets a site without a location when the lat is nil, and the lng is nil in search" do
    collection.sites.make lat: nil, lng: nil

    get :search, collection_id: collection.id

    result = JSON.parse response.body
    sites = result["sites"]

    expect(sites.first).not_to include("lat")
    expect(sites.first).not_to include("lng")
  end

  it "gets a site searching by its full name" do
    collection.sites.make name: 'Target'
    collection.sites.make name: 'NotThisOne'

    get :search, collection_id: collection.id, sitename: 'Target'

    result = JSON.parse response.body
    sites = result["sites"]

    expect(sites.first).to include("name")
    expect(sites.first["name"]).to eq("Target")
  end

  it "gets a site searching by its prefix" do
    collection.sites.make name: 'Target'
    collection.sites.make name: 'NotThisOne'

    get :search, collection_id: collection.id, sitename: 'Tar'

    result = JSON.parse response.body
    sites = result["sites"]

    expect(sites.first).to include("name")
    expect(sites.first["name"]).to eq("Target")
  end

  it "doesn't get any site when name doesn't match" do
    collection.sites.make name: 'Target'
    collection.sites.make name: 'NotThisOne'

    get :search, collection_id: collection.id, sitename: 'TakeThat'

    result = JSON.parse response.body
    sites = result["sites"]

    expect(sites).to be_empty
  end

  it "gets multiple matching sites by name" do
    collection.sites.make name: 'Target'
    collection.sites.make name: 'NotThisOne'
    collection.sites.make name: 'TallLand'

    get :search, collection_id: collection.id, sitename: 'Ta'

    result = JSON.parse response.body
    sites = result["sites"]

    expect(sites.size).to eq(2)
    expect(sites.map { |site| site['name'] }).to include 'Target'
    expect(sites.map { |site| site['name'] }).to include 'TallLand'
    expect(sites.first['name']).not_to eq('NotThisOne')
    expect(sites.second['name']).not_to eq('NotThisOne')
  end

  it "applys multiple filters" do
    layer = collection.layers.make
    numeric = layer.numeric_fields.make :code => 'numeric'

    collection.sites.make name: 'Target', properties: { numeric.es_code => 25 }
    collection.sites.make name: 'NotThisOne', properties: { numeric.es_code => 25 }
    collection.sites.make name: 'TallLand', properties: { numeric.es_code => 20 }

    get :search, collection_id: collection.id, sitename: 'Ta', numeric.es_code => { "=" => 25 }

    result = JSON.parse response.body
    sites = result["sites"]

    expect(sites.size).to eq(1)
    expect(sites.first['name']).not_to eq('TallLand')
    expect(sites.first['name']).to eq('Target')
    expect(sites.first).to include('properties')
    expect(sites.first['properties']).to include numeric.es_code
    expect(sites.first['properties'][numeric.es_code]).to eq(25)
  end

end
