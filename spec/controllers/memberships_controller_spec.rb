require 'spec_helper'

describe MembershipsController do
  include Devise::TestHelpers

  let!(:user) { User.make email: 'foo@test.com' }
  let!(:user_2) { User.make email: 'bar@test.com' }
  let!(:collection) { user.create_collection(Collection.make_unsaved) }


  describe "index" do

    let(:membership) { collection.memberships.create! user_id: user_2.id, admin: false }

    before(:each) { sign_in user }

    it "collection admin should be able to write name and location" do
      get :index, collection_id: collection.id
      json = JSON.parse response.body
      json[0]["user_id"].should eq(user.id)
      json[0]["admin"].should eq(true)
      json[0]["name"].should eq("update")
      json[0]["location"].should eq("update")
    end

    it "for collection member should include default_fields permissions in json" do
      membership.set_access(object: 'name', new_action: 'update')
      membership.set_access(object: 'location', new_action: 'read')

      get :index, collection_id: collection.id
      json = JSON.parse response.body
      json[1]["user_id"].should eq(user_2.id)
      json[1]["admin"].should eq(false)
      json[1]["name"].should eq("update")
      json[1]["location"].should eq("read")
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
