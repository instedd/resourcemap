require 'spec_helper'

describe Api::MembershipsController do
  include Devise::TestHelpers
  render_views

  let(:user) { User.make }
  let(:non_admin_user) { User.make }
  let(:collection) { user.create_collection(Collection.make) }

  before(:each) { Membership.check_and_create(non_admin_user.email, collection.id) }

  describe 'as admin' do
    before(:each) { sign_in user }

    it "should get all memberships" do
      get :index, collection_id: collection.id
      json = JSON.parse response.body
      json.count.should eq(2)
      json[0]['user_id'].should eq(user.id)
      json[1]['user_id'].should eq(non_admin_user.id)
    end

    it "should return all users not in collection as invitable" do
      new_user = User.make
      get :invitable, collection_id: collection.id
      json = JSON.parse response.body
      json.should have(1).item
      json[0].should eq(new_user.email)
    end

    context 'create' do

      it "should create membership for new user" do
        new_user = User.make
        post :create, collection_id: collection.id, email: new_user.email
        json = JSON.parse response.body
        json['user_id'].should eq(new_user.id)
        collection.memberships.count.should eq(3)
      end

      it "should return error for non-existant user" do
        post :create, collection_id: collection.id, email: 'random@example.com'
        response.status.should eq(422)
        json = JSON.parse response.body
        json['error_code'].should eq(2)
      end

      it "should return error for non-existant collection" do
        new_user = User.make
        post :create, collection_id: 0, email: new_user.email
        response.status.should eq(422)
      end

      it "should return the membership if it already exists" do
        post :create, collection_id: collection.id, email: user.email
        response.status.should eq(200)
        json = JSON.parse response.body
        json['user_id'].should eq(user.id)
        collection.memberships.count.should eq(2)
      end
    end

    it "should delete a membership" do
      collection.memberships.count.should eq(2)
      delete :destroy, collection_id: collection.id, id: non_admin_user.id
      response.should be_ok
      collection.memberships.count.should eq(1)
    end
  end

  describe 'as member' do
    before(:each) { sign_in non_admin_user }

    it "should not get memberships" do
      get :index, collection_id: collection.id
      json = JSON.parse response.body
      json['message'].should include("Forbidden")
    end

    it "should not delete a membership" do
      delete :destroy, collection_id: collection.id, id: user.id
      response.should be_forbidden
    end

  end

  describe "admin flag" do
    before(:each) { sign_in user }

    it "should set admin" do
      post :set_admin, collection_id: collection.id, id: non_admin_user.id

      response.should be_ok

      membership = collection.memberships.find_by_user_id non_admin_user.id
      membership.admin.should be_truthy
    end

    it "should unset admin" do
      membership = collection.memberships.find_by_user_id non_admin_user.id
      membership.change_admin_flag(true)
      membership.admin.should be_truthy
      post :unset_admin, collection_id: collection.id, id: non_admin_user.id
      membership = collection.memberships.find_by_user_id non_admin_user.id
      membership.admin.should be_falsey
    end
  end
end
