require 'spec_helper'

describe MembershipsController, :type => :controller do
  include Devise::Test::ControllerHelpers

  let(:user) { User.make email: 'foo@test.com' }
  let(:user_2) { User.make email: 'bar@test.com' }
  let(:collection) { user.create_collection(Collection.make_unsaved) }
  let(:anonymous) { Membership::Anonymous.new collection, user }
  let(:membership) { collection.memberships.create! user_id: user_2.id, admin: false }

  describe "index" do
    let(:layer) { collection.layers.make }

    it "collection admin should be able to write name and location" do
      sign_in user
      get :index, params: { collection_id: collection.id }
      user_membership = collection.memberships.where(user_id:user.id).first
      json = JSON.parse response.body
      expect(json["members"][0]).to eq(user_membership.as_json.with_indifferent_access)
    end

    it "should not return memberships for non admin user" do
      sign_in user_2
      get :index, params: { collection_id: collection.id }
      expect(response.body).to be_blank
    end


    it "should include anonymous's membership " do
      layer
      sign_in user
      get :index, params: { collection_id: collection.id }
      json = JSON.parse response.body
      expect(json["anonymous"]).to eq(anonymous.as_json.with_indifferent_access)
    end
  end

  describe "Changed membership permissions" do
    before(:each) { sign_in user }
    let(:user2){ User.make email: 'user2@gmail.com'}
    let(:layer) { collection.layers.make }
    let(:membership){collection.memberships.create! user_id:user2.id}

    it "should create activity when a membership is created" do
      collection
      Activity.delete_all
      post :create, params: { collection_id: collection.id, email: user2.email }
      expect(Activity.count).to eq(1)
      activity = Activity.first
      expect(activity.item_type).to eq('membership')
      expect(activity.action).to eq('created')
      expect(activity.user_id).to eq(user.id)
      expect(activity.collection_id).to eq(collection.id)
      expect(activity.data['user']).to eq(user2.email)
    end

    it "should create activity when a membership is deleted" do
      membership
      Activity.delete_all
      post :destroy, params: { collection_id: collection.id, id: user2.id }
      expect(Activity.count).to eq(1)
      activity = Activity.first
      expect(activity.item_type).to eq('membership')
      expect(activity.action).to eq('deleted')
      expect(activity.user_id).to eq(user.id)
      expect(activity.collection_id).to eq(collection.id)
      expect(activity.data['user']).to eq(user2.email)
    end

    it "should create activity when layer_membership is created" do
      layer
      membership
      Activity.delete_all
      post :set_layer_access, params: { collection_id: collection.id, verb: 'read', access: 'true', id: user2.id, layer_id: layer.id }
      expect(Activity.count).to eq(1)
      activity = Activity.first
      expect(activity.item_type).to eq('layer_membership')
      expect(activity.action).to eq('changed')
      expect(activity.user_id).to eq(user.id)
      expect(activity.collection_id).to eq(collection.id)
      expect(activity.data['user']).to eq(user2.email)
      expect(activity.data['name']).to eq(layer.name)
      expect(activity.data['previous_permission']).to eq('none')
      expect(activity.data['new_permission']).to eq('read')
    end

    it "should create activity when layer_membership is deleted" do
      layer
      membership
      post :set_layer_access, params: { collection_id: collection.id, verb: 'read', access: 'true', id: user2.id, layer_id: layer.id }
      Activity.delete_all
      post :set_layer_access, params: { collection_id: collection.id, verb: 'read', access: 'false', id: user2.id, layer_id: layer.id }
      expect(Activity.count).to eq(1)
      activity = Activity.first
      expect(activity.item_type).to eq('layer_membership')
      expect(activity.action).to eq('changed')
      expect(activity.user_id).to eq(user.id)
      expect(activity.collection_id).to eq(collection.id)
      expect(activity.data['user']).to eq(user2.email)
      expect(activity.data['name']).to eq(layer.name)
      expect(activity.data['previous_permission']).to eq('read')
      expect(activity.data['new_permission']).to eq('none')
    end

    it "shouldn't create activity when layer_membership is not changed" do
      layer
      membership
      post :set_layer_access, params: { collection_id: collection.id, verb: 'read', access: 'true', id: user2.id, layer_id: layer.id }
      Activity.delete_all
      post :set_layer_access, params: { collection_id: collection.id, verb: 'read', access: 'true', id: user2.id, layer_id: layer.id }
      expect(Activity.count).to eq(0)
    end

    it "shouldn't create activity when layer_membership is not changed 2" do
      layer
      membership
      post :set_layer_access, params: { collection_id: collection.id, verb: 'write', access: 'true', id: user2.id, layer_id: layer.id }
      Activity.delete_all
      post :set_layer_access, params: { collection_id: collection.id, verb: 'write', access: 'true', id: user2.id, layer_id: layer.id }
      expect(Activity.count).to eq(0)
    end

    it "should create activity when layer_membership changed" do
      layer
      membership
      post :set_layer_access, params: { collection_id: collection.id, verb: 'read', access: 'true', id: user2.id, layer_id: layer.id }
      Activity.delete_all
      post :set_layer_access, params: { collection_id: collection.id, verb: 'write', access: 'true', id: user2.id, layer_id: layer.id }
      expect(Activity.count).to eq(1)
      activity = Activity.first
      expect(activity.item_type).to eq('layer_membership')
      expect(activity.action).to eq('changed')
      expect(activity.user_id).to eq(user.id)
      expect(activity.collection_id).to eq(collection.id)
      expect(activity.data['user']).to eq(user2.email)
      expect(activity.data['name']).to eq(layer.name)
      expect(activity.data['previous_permission']).to eq('read')
      expect(activity.data['new_permission']).to eq('update')
      expect(activity.description).to eq("Permission changed from read to update in layer '#{layer.name}' for #{user2.email}")
    end

    it "should create activity when name permission changed" do
      membership
      Activity.delete_all
      post :set_access, params: { object: 'name', new_action: 'update', collection_id: collection.id, id: user2.id }
      expect(Activity.count).to eq(1)
      activity = Activity.first
      expect(activity.item_type).to eq('name_permission')
      expect(activity.action).to eq('changed')
      expect(activity.data["changes"]).to eq(["read", "update"])
      expect(activity.description).to eq("Permission changed from read to update in name layer for #{user2.email}")
      expect(activity.user_id).to eq(user.id)
      expect(activity.collection_id).to eq(collection.id)
      expect(activity.data['user']).to eq(user2.email)
    end

    it "shouldn't create activity when name permission unchanged" do
      membership
      post :set_access, params: { object: 'name', new_action: 'update', collection_id: collection.id, id: user2.id }
      Activity.delete_all
      post :set_access, params: { object: 'name', new_action: 'update', collection_id: collection.id, id: user2.id }
      expect(Activity.count).to eq(0)
    end

    it "should create activity when location permission changed" do
      membership
      Activity.delete_all
      post :set_access, params: { object: 'location', new_action: 'update', collection_id: collection.id, id: user2.id }
      expect(Activity.count).to eq(1)
      activity = Activity.first
      expect(activity.item_type).to eq('location_permission')
      expect(activity.action).to eq('changed')
      expect(activity.data["changes"]).to eq(["read", "update"])
      expect(activity.description).to eq("Permission changed from read to update in location layer for #{user2.email}")
      expect(activity.user_id).to eq(user.id)
      expect(activity.collection_id).to eq(collection.id)
      expect(activity.data['user']).to eq(user2.email)
    end

    it "shouldn't create activity when location permission unchanged" do
      membership
      post :set_access, params: { object: 'location', new_action: 'update', collection_id: collection.id, id: user2.id }
      Activity.delete_all
      post :set_access, params: { object: 'location', new_action: 'update', collection_id: collection.id, id: user2.id }
      expect(Activity.count).to eq(0)
    end

    it "should create activity when name permission changed for anonymous user" do
      membership
      Activity.delete_all
      post :set_access_anonymous_user, params: { object: 'name', new_action: 'read', collection_id: collection.id }
      expect(Activity.count).to eq(1)
      activity = Activity.first
      expect(activity.item_type).to eq('anonymous_name_location_permission')
      expect(activity.action).to eq('changed')
      expect(activity.user_id).to eq(user.id)
      expect(activity.collection_id).to eq(collection.id)
      expect(activity.data["built_in_layer"]).to eq("name")
      expect(activity.data["changes"]).to eq(["none", "read"])
      expect(activity.description).to eq("Permission changed from none to read in name layer for anonymous users")
    end

    it "should create activity when location permission changed for anonymous user" do
      membership
      Activity.delete_all
      post :set_access_anonymous_user, params: { object: 'location', new_action: 'read', collection_id: collection.id }
      expect(Activity.count).to eq(1)
      activity = Activity.first
      expect(activity.item_type).to eq('anonymous_name_location_permission')
      expect(activity.action).to eq('changed')
      expect(activity.user_id).to eq(user.id)
      expect(activity.collection_id).to eq(collection.id)
      expect(activity.data["built_in_layer"]).to eq("location")
      expect(activity.data["changes"]).to eq(["none", "read"])
      expect(activity.description).to eq("Permission changed from none to read in location layer for anonymous users")
    end

    it "should create activity when layer membership changed for anonymous user" do
      layer
      membership
      Activity.delete_all
      post :set_layer_access_anonymous_user, params: { layer_id: layer.id, verb: 'read', access: 'true', collection_id: collection.id }
      expect(Activity.count).to eq(1)
      activity = Activity.first
      expect(activity.item_type).to eq('anonymous_layer_permission')
      expect(activity.action).to eq('changed')
      expect(activity.user_id).to eq(user.id)
      expect(activity.collection_id).to eq(collection.id)
      expect(activity.data['name']).to eq(layer.name)
      expect(activity.data["changes"]).to eq(["none", "read"])
      expect(activity.description).to eq("Permission changed from none to read in layer '#{layer.name}' for anonymous users")
    end

    it "should create activity when layer_membership changed" do
      layer
      membership
      post :set_layer_access, params: { collection_id: collection.id, verb: 'read', access: 'true', id: user2.id, layer_id: layer.id }
      Activity.delete_all
      post :set_layer_access, params: { collection_id: collection.id, verb: 'write', access: 'true', id: user2.id, layer_id: layer.id }
      expect(Activity.count).to eq(1)
      activity = Activity.first
      activity.data = {}
      activity.save!
      activity.reload
      expect(activity.item_type).to eq('layer_membership')
      expect(activity.action).to eq('changed')
      expect{activity.description}.not_to raise_error
      expect(activity.description).not_to eq("There was an error processing this activity")
    end

    it "should handle correctly the activity description when location permission changed and changes not present" do
      membership
      Activity.delete_all
      post :set_access, params: { object: 'location', new_action: 'update', collection_id: collection.id, id: user2.id }
      expect(Activity.count).to eq(1)
      activity = Activity.first
      activity.data = {}
      activity.save!
      activity.reload
      expect(activity.item_type).to eq('location_permission')
      expect(activity.action).to eq('changed')
      expect{activity.description}.not_to raise_error
      expect(activity.description).not_to eq("There was an error processing this activity")
    end

    it "should handle correctly the activity description when name permission changed for anonymous user and changes not present" do
      membership
      Activity.delete_all
      post :set_access_anonymous_user, params: { object: 'name', new_action: 'read', collection_id: collection.id }
      expect(Activity.count).to eq(1)
      activity = Activity.first
      activity.data = {}
      activity.save!
      activity.reload
      expect(activity.item_type).to eq('anonymous_name_location_permission')
      expect(activity.action).to eq('changed')
      expect{activity.description}.not_to raise_error
      expect(activity.description).not_to eq("There was an error processing this activity")
    end

    it "should handle correctly the activity description when location permission changed for anonymous user and changes not present" do
      membership
      Activity.delete_all
      post :set_access_anonymous_user, params: { object: 'location', new_action: 'read', collection_id: collection.id }
      expect(Activity.count).to eq(1)
      activity = Activity.first
      activity.data = {}
      activity.save!
      activity.reload
      expect(activity.item_type).to eq('anonymous_name_location_permission')
      expect(activity.action).to eq('changed')
      expect{activity.description}.not_to raise_error
      expect(activity.description).not_to eq("There was an error processing this activity")
    end

    it "should handle correctly the activity description when layer membership changed for anonymous user and changes not present" do
      layer
      membership
      Activity.delete_all
      post :set_layer_access_anonymous_user, params: { layer_id: layer.id, verb: 'read', access: 'true', collection_id: collection.id }
      expect(Activity.count).to eq(1)
      activity = Activity.first
      activity.data = {}
      activity.save!
      activity.reload
      expect(activity.item_type).to eq('anonymous_layer_permission')
      expect(activity.action).to eq('changed')
      expect{activity.description}.not_to raise_error
      expect(activity.description).not_to eq("There was an error processing this activity")
    end
  end

  describe "search" do
    before(:each) { sign_in user }

    it "should find users that have membership" do
      get :search, params: { collection_id: collection.id, term: 'bar' }
      expect(JSON.parse(response.body).count).to eq(0)
    end

    it "should find user" do
      get :search, params: { collection_id: collection.id, term: 'foo' }
      json = JSON.parse response.body

      expect(json.size).to eq(1)
      expect(json[0]).to eq('foo@test.com')
    end

    context "without term" do
      it "should return all users in the collection" do
        get :search, params: { collection_id: collection.id }
        expect(JSON.parse(response.body).count).to eq(1)
      end
    end
  end

  describe "admin flag" do
    before(:each) { sign_in user }

    it "should set admin" do
      membership
      post :set_admin, params: { collection_id: collection.id, id: user_2.id }
      membership = collection.memberships.find_by_user_id user_2.id
      expect(membership.admin).to be_truthy
    end

    it "should unset admin" do
      membership.change_admin_flag(true)
      expect(membership.admin).to be_truthy
      post :unset_admin, params: { collection_id: collection.id, id: user_2.id }
      membership = collection.memberships.find_by_user_id user_2.id
      expect(membership.admin).to be_falsey
    end
  end

  describe "user permissions" do
    it "should destroy another user's membership as admin" do
      sign_in user
      membership
      expect {
        delete :destroy, params: { collection_id: collection.id, id: user_2.id }
      }.to change { Membership.count }.by -1
    end

    it "should not destroy another user's membership as a regular user" do
      sign_in user_2
      membership
      user_3 = User.make
      collection.memberships.create! user_id: user_3.id, admin: false

      expect {
        delete :destroy, params: { collection_id: collection.id, id: user_3.id }
      }.to change { Membership.count }.by 0
    end

    it "should allow user to leave collection as regular user" do
      sign_in user_2
      membership
      expect {
        delete :leave_collection, params: { collection_id: collection.id }
      }.to change { Membership.count }.by -1
    end
  end
end
