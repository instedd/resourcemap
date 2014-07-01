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

  # describe "opt out" do
  #   it "user should opt out of the collection when they are non admin members " do
  #     sign_in user_2
  #     post :opt_out_of_collection, collection_id: collection.id, id: user_2.id
  #     response.status.should eq(200)
  #   end
  # end
end
