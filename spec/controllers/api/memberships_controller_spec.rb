require 'spec_helper'

describe Api::MembershipsController, :type => :controller do
  include Devise::TestHelpers
  render_views

  let(:user) { User.make! }
  let(:non_admin_user) { User.make! }
  let(:collection) { user.create_collection(Collection.make!) }

  before(:each) { Membership.check_and_create(non_admin_user.email, collection.id) }

  describe 'as admin' do
    before(:each) { sign_in user }

    it "should get all memberships" do
      get :index, collection_id: collection.id
      json = JSON.parse response.body
      expect(json.count).to eq(2)
      expect(json[0]['user_id']).to eq(user.id)
      expect(json[1]['user_id']).to eq(non_admin_user.id)
    end

    it "should return all users not in collection as invitable" do
      new_user = User.make!
      get :invitable, collection_id: collection.id
      json = JSON.parse response.body
      expect(json.size).to eq(1)
      expect(json[0]).to eq(new_user.email)
    end

    context 'create' do

      it "should create membership for new user" do
        new_user = User.make!
        post :create, collection_id: collection.id, email: new_user.email
        json = JSON.parse response.body
        expect(json['user_id']).to eq(new_user.id)
        expect(collection.memberships.count).to eq(3)
      end

      it "should return error for non-existant user" do
        post :create, collection_id: collection.id, email: 'random@example.com'
        expect(response.status).to eq(422)
        json = JSON.parse response.body
        expect(json['error_code']).to eq(2)
      end

      it "should return error for non-existant collection" do
        new_user = User.make!
        post :create, collection_id: 0, email: new_user.email
        expect(response.status).to eq(422)
      end

      it "should return the membership if it already exists" do
        post :create, collection_id: collection.id, email: user.email
        expect(response.status).to eq(200)
        json = JSON.parse response.body
        expect(json['user_id']).to eq(user.id)
        expect(collection.memberships.count).to eq(2)
      end
    end

    it "should delete a membership" do
      expect(collection.memberships.count).to eq(2)
      delete :destroy, collection_id: collection.id, id: non_admin_user.id
      expect(response).to be_ok
      expect(collection.memberships.count).to eq(1)
    end
  end

  describe 'as member' do
    before(:each) { sign_in non_admin_user }

    it "should not get memberships" do
      get :index, collection_id: collection.id
      json = JSON.parse response.body
      expect(json['message']).to include("Forbidden")
    end

    it "should not delete a membership" do
      delete :destroy, collection_id: collection.id, id: user.id
      expect(response).to be_forbidden
    end

  end

  describe "admin flag" do
    before(:each) { sign_in user }

    it "should set admin" do
      post :set_admin, collection_id: collection.id, id: non_admin_user.id

      expect(response).to be_ok

      membership = collection.memberships.find_by_user_id non_admin_user.id
      expect(membership.admin).to be_truthy
    end

    it "should unset admin" do
      membership = collection.memberships.find_by_user_id non_admin_user.id
      membership.change_admin_flag(true)
      expect(membership.admin).to be_truthy
      post :unset_admin, collection_id: collection.id, id: non_admin_user.id
      membership = collection.memberships.find_by_user_id non_admin_user.id
      expect(membership.admin).to be_falsey
    end
  end
end
