require 'spec_helper'

describe MembershipsController do
  include Devise::TestHelpers

  let(:user) { User.make email: 'foo@test.com' }
  let(:collection) { user.create_collection(Collection.make_unsaved) }
  let(:anonymous) { Membership::Anonymous.new collection, user }

  describe "index" do
    let(:membership) { collection.memberships.create! user_id: user_2.id, admin: false }

    before(:each) { sign_in user }

    let(:layer) { collection.layers.make }
    it "should include admins's membership " do
      layer
      get :index, collection_id: collection.id
      user_membership = collection.memberships.where(user_id:user.id).first
      json = JSON.parse response.body
      json["members"][0].should eq(user_membership.as_json.with_indifferent_access)
    end


    it "should include anonymous's membership " do
      layer
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
end
