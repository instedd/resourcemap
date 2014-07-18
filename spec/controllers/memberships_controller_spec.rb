require 'spec_helper'

describe MembershipsController do
  include Devise::TestHelpers

  let(:user) { User.make email: 'foo@test.com' }
  let(:user_2) { User.make email: 'bar@test.com' }
  let(:collection) { user.create_collection(Collection.make_unsaved) }
  let(:anonymous) { Membership::Anonymous.new collection, user }
  let(:membership) { collection.memberships.create! user_id: user_2.id, admin: false }

  describe "index" do
    let(:layer) { collection.layers.make }

    it "collection admin should be able to write name and location" do
      sign_in user
      get :index, collection_id: collection.id
      user_membership = collection.memberships.where(user_id:user.id).first
      json = JSON.parse response.body
      json["members"][0].should eq(user_membership.as_json.with_indifferent_access)
    end

    it "should not return memberships for non admin user" do
      sign_in user_2
      get :index, collection_id: collection.id
      response.body.should be_blank
    end


    it "should include anonymous's membership " do
      layer
      sign_in user
      get :index, collection_id: collection.id
      json = JSON.parse response.body
      json["anonymous"].should eq(anonymous.as_json.with_indifferent_access)
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
      post :create, collection_id: collection.id, email: user2.email
      Activity.count.should eq(1)
      activity = Activity.first
      activity.item_type.should eq('membership')
      activity.action.should eq('created')
      activity.user_id.should eq(user.id)
      activity.collection_id.should eq(collection.id)
      activity.data['user'].should eq(user2.email)
    end

    it "should create activity when a membership is deleted" do
      membership
      Activity.delete_all
      post :destroy, collection_id: collection.id, id: user2.id
      Activity.count.should eq(1)
      activity = Activity.first
      activity.item_type.should eq('membership')
      activity.action.should eq('deleted')
      activity.user_id.should eq(user.id)
      activity.collection_id.should eq(collection.id)
      activity.data['user'].should eq(user2.email)
    end

    it "should create activity when layer_membership is created" do
      layer
      membership
      Activity.delete_all
      post :set_layer_access, collection_id: collection.id, verb: 'read', access: 'true', id: user2.id, layer_id: layer.id
      Activity.count.should eq(1)
      activity = Activity.first
      activity.item_type.should eq('layer_membership')
      activity.action.should eq('changed')
      activity.user_id.should eq(user.id)
      activity.collection_id.should eq(collection.id)
      activity.data['user'].should eq(user2.email)
      activity.data['name'].should eq(layer.name)
      activity.data['previous_permission'].should eq('none')
      activity.data['new_permission'].should eq('read')
    end

    it "should create activity when layer_membership is deleted" do
      layer
      membership
      post :set_layer_access, collection_id: collection.id, verb: 'read', access: 'true', id: user2.id, layer_id: layer.id
      Activity.delete_all
      post :set_layer_access, collection_id: collection.id, verb: 'read', access: 'false', id: user2.id, layer_id: layer.id
      Activity.count.should eq(1)
      activity = Activity.first
      activity.item_type.should eq('layer_membership')
      activity.action.should eq('changed')
      activity.user_id.should eq(user.id)
      activity.collection_id.should eq(collection.id)
      activity.data['user'].should eq(user2.email)
      activity.data['name'].should eq(layer.name)
      activity.data['previous_permission'].should eq('read')
      activity.data['new_permission'].should eq('none')
    end

    it "should create activity when layer_membership changed" do
      layer
      membership
      post :set_layer_access, collection_id: collection.id, verb: 'read', access: 'true', id: user2.id, layer_id: layer.id
      Activity.delete_all
      post :set_layer_access, collection_id: collection.id, verb: 'write', access: 'true', id: user2.id, layer_id: layer.id
      Activity.count.should eq(1)
      activity = Activity.first
      activity.item_type.should eq('layer_membership')
      activity.action.should eq('changed')
      activity.user_id.should eq(user.id)
      activity.collection_id.should eq(collection.id)
      activity.data['user'].should eq(user2.email)
      activity.data['name'].should eq(layer.name)
      activity.data['previous_permission'].should eq('read')
      activity.data['new_permission'].should eq('update')
    end

    it "should create activity when name permission changed" do
      membership
      Activity.delete_all
      post :set_access, object: 'name', new_action: 'update', collection_id: collection.id, id: user2.id
      Activity.count.should eq(1)
      activity = Activity.first
      activity.item_type.should eq('name_permission')
      activity.action.should eq('changed')
      activity.user_id.should eq(user.id)
      activity.collection_id.should eq(collection.id)
      activity.data['user'].should eq(user2.email)
    end

    it "should create activity when location permission changed" do
      membership
      Activity.delete_all
      post :set_access, object: 'location', new_action: 'update', collection_id: collection.id, id: user2.id
      Activity.count.should eq(1)
      activity = Activity.first
      activity.item_type.should eq('location_permission')
      activity.action.should eq('changed')
      activity.user_id.should eq(user.id)
      activity.collection_id.should eq(collection.id)
      activity.data['user'].should eq(user2.email)
    end

    it "should create activity when name permission changed for anonymous user" do
      membership
      Activity.delete_all
      post :set_access_anonymous_user, object: 'name', new_action: 'read', collection_id: collection.id
      Activity.count.should eq(1)
      activity = Activity.first
      activity.item_type.should eq('anonymous_name_location_permission')
      activity.action.should eq('changed')
      activity.user_id.should eq(user.id)
      activity.collection_id.should eq(collection.id)
    end

    it "should create activity when location permission changed for anonymous user" do
      membership
      Activity.delete_all
      post :set_access_anonymous_user, object: 'location', new_action: 'read', collection_id: collection.id
      Activity.count.should eq(1)
      activity = Activity.first
      activity.item_type.should eq('anonymous_name_location_permission')
      activity.action.should eq('changed')
      activity.user_id.should eq(user.id)
      activity.collection_id.should eq(collection.id)
    end

    it "should create activity when layer membership changed for anonymous user" do
      layer
      membership
      Activity.delete_all
      post :set_layer_access_anonymous_user, layer_id: layer.id, verb: 'read', access: 'true', collection_id: collection.id
      Activity.count.should eq(1)
      activity = Activity.first
      activity.item_type.should eq('anonymous_layer_permission')
      activity.action.should eq('changed')
      activity.user_id.should eq(user.id)
      activity.collection_id.should eq(collection.id)
      activity.data['name'].should eq(layer.name)
    end

  end

  describe "search" do
    before(:each) { sign_in user }

    it "should find users that have membership" do
      get :search, collection_id: collection.id, term: 'bar'
      JSON.parse(response.body).count.should == 0
    end

    it "should find user" do
      get :search, collection_id: collection.id, term: 'foo'
      json = JSON.parse response.body

      json.size.should == 1
      json[0].should == 'foo@test.com'
    end

    context "without term" do
      it "should return all users in the collection" do
        get :search, collection_id: collection.id
        JSON.parse(response.body).count.should == 1
      end
    end
  end

  describe "admin flag" do
    before(:each) { sign_in user }

    it "should set admin" do
      membership
      post :set_admin, collection_id: collection.id, id: user_2.id
      membership = collection.memberships.find_by_user_id user_2.id
      membership.admin.should be_true
    end

    it "should unset admin" do
      membership.change_admin_flag(true)
      membership.admin.should be_true
      post :unset_admin, collection_id: collection.id, id: user_2.id
      membership = collection.memberships.find_by_user_id user_2.id
      membership.admin.should be_false
    end
  end
end
