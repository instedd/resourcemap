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
      get :index, id: collection.id
      json = JSON.parse response.body
      json.count.should eq(2)
      json[0]['user_id'].should eq(user.id)
      json[1]['user_id'].should eq(non_admin_user.id)
    end

    it "should return all users not in collection as invitable" do
      new_user = User.make
      get :invitable, id: collection.id
      json = JSON.parse response.body
      json.should have(1).item
      json[0].should eq(new_user.email)
    end

    context 'create' do

      it "should create membership for new user" do
        new_user = User.make
        post :create, id: collection.id, email: new_user.email
        json = JSON.parse response.body
        json['user_id'].should eq(new_user.id)
        collection.memberships.count.should eq(3)
      end

      it "should return error for non-existant user" do
        post :create, id: collection.id, email: 'random@example.com'
        response.status.should eq(422)
        json = JSON.parse response.body
        json['error_code'].should eq(2)
      end

      it "should return error for non-existant collection" do
        new_user = User.make
        post :create, id: 0, email: new_user.email
        response.status.should eq(422)
      end

      it "should return the membership if it already exists" do
        post :create, id: collection.id, email: user.email
        response.status.should eq(200)
        json = JSON.parse response.body
        json['user_id'].should eq(user.id)
        collection.memberships.count.should eq(2)
      end
    end
  end

  describe 'as member' do
    before(:each) { sign_in non_admin_user }

    it "should not get memberships" do
      get :index, id: collection.id
      json = JSON.parse response.body
      json['message'].should include("Forbidden")
    end

  end
end
