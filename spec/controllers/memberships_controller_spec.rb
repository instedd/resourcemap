require 'spec_helper'

describe MembershipsController do
  include Devise::TestHelpers

  let(:user) { User.make email: 'foo@test.com' }
  let(:user_2) { User.make email: 'bar@test.com' }
  let(:collection) { user.create_collection(Collection.make_unsaved) }


  describe "index" do

    let(:membership) { collection.memberships.create! user_id: user_2.id, admin: false }

    before(:each) { sign_in user }

    it "collection admin should be able to write name and location" do
      get :index, collection_id: collection.id
      json = JSON.parse response.body
      json["members"][0]["user_id"].should eq(user.id)
      json["members"][0]["admin"].should eq(true)
      json["members"][0]["name"].should eq("update")
      json["members"][0]["location"].should eq("update")
    end

    it "for collection member should include default_fields permissions in json" do
      membership.set_access(object: 'name', new_action: 'update')
      membership.set_access(object: 'location', new_action: 'read')

      get :index, collection_id: collection.id
      json = JSON.parse response.body
      json["members"][1]["user_id"].should eq(user_2.id)
      json["members"][1]["admin"].should eq(false)
      json["members"][1]["name"].should eq("update")
      json["members"][1]["location"].should eq("read")
    end

    describe "anonymous" do
      let(:collection2) { user.create_collection(Collection.make({public: true})) }

      describe "built in fields" do
        it "should not have read permissions in name or location when collection is private" do
          get :index, collection_id: collection.id
          json = JSON.parse response.body
          json["anonymous"]["name"].should eq("none")
          json["anonymous"]["location"].should eq("none")
        end

        it "should have read permissions in layers when collection is public" do
          get :index, collection_id: collection2.id
          json = JSON.parse response.body
          json["anonymous"]["name"].should eq("read")
          json["anonymous"]["location"].should eq("read")
        end
      end

      describe "previously configured layers" do
        subject { get :index, collection_id: collection2.id }

        it "should have proper permission" do
          l1 = collection2.layers.make({anonymous_user_permission: "read"})
          l2 = collection2.layers.make({anonymous_user_permission: "none"})

          anon = JSON.parse(subject.body)["anonymous"]

          [l1, l2].each {|l| anon[l.id.to_s].should eq(l.anonymous_user_permission)}
        end
      end

      it "should update anonymous access from none to read" do
        layer = collection2.layers.make({ anonymous_user_permission: "none" })

        post :set_layer_access_anonymous_user, collection_id: collection2.id, layer_id: layer.id,
        verb: 'read'

        response.body.should eq('ok')

        layer.reload
        layer.anonymous_user_permission.should eq("read")
      end
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
