require 'spec_helper'

describe User do
  it { should have_many :memberships }
  it { should have_many :collections }

  it "should be confirmed" do
    user = User.make confirmed_at: nil
    user.confirmed?.should be_false
    user.confirm!
    user.confirmed?.should be_true
  end

  it "creates a collection" do
    user = User.make
    collection = Collection.make_unsaved
    user.create_collection(collection).should eq(collection)
    user.collections.should eq([collection])
    user.memberships.first.should be_admin
  end

  it "fails to create a collection if invalid" do
    user = User.make
    collection = Collection.make_unsaved
    collection.name = nil
    user.create_collection(collection).should be_false
    user.collections.should be_empty
  end

  context "admins?" do
    let!(:user) { User.make }
    let!(:collection) { user.create_collection Collection.make_unsaved }

    it "admins a collection" do
      user.admins?(collection).should be_true
    end

    it "doesn't admin a collection if belongs but not admin" do
      user2 = User.make
      user2.memberships.create! :collection_id => collection.id
      user2.admins?(collection).should be_false
    end

    it "doesn't admin a collection if doesn't belong" do
      User.make.admins?(collection).should be_false
    end
  end

  context "activities" do
    let!(:user) { User.make }
    let!(:collection) { user.create_collection Collection.make_unsaved }

    before(:each) do
      Activity.delete_all
    end

    it "returns activities for user membership" do
      Activity.make collection_id: collection.id, user_id: user.id, item_type: 'collection', action: 'created'

      user.activities.length.should eq(1)
    end

    it "doesn't return activities for user membership" do
      user2 = User.make

      Activity.make collection_id: collection.id, user_id: user.id, item_type: 'collection', action: 'created'

      user2.activities.length.should eq(0)
    end
  end

  describe "Permission" do
    before(:each) do
      @user1  = User.make
      @user = User.create(:email => "demo@instedd.org", :password => "123456", :phone_number => "855123456789")
      @collection = Collection.make
      @site  = @collection.sites.make
      @layer = @collection.layers.create(:name => "health center")
      @properties =[{:code=>"AB", :value=>"26"}]
      Field.create(:collection_id => @collection.id, :layer_id => @layer.id, :code => "AB", :ord => 1, :kind => "numeric")
    end

    it "should be able to view and update layer" do
      @collection.memberships.create(:user => @user, :admin => false)
      @collection.layer_memberships.create( :layer_id => @layer.id, :read => true, :user_id => @user.id, :write => true)
      Field.create(:collection_id => @collection.id, :layer_id => @layer.id, :code => "AB", :ord => 1, :kind => "numeric")
      @user.can_view?(@collection, @properties[0][:code]).should be_true
      @user.can_update?(@site, @properties).should be_true
    end

    context "can update" do
      it "should return true when user have write permission on layer" do
        @collection.layer_memberships.create( :layer_id => @layer.id, :read => true, :user_id => @user.id, :write => true)
        @user.validate_layer_write_permission(@site, @properties).should be_true
      end

      it "should return false when user don't have write permission on layer" do
        @user.validate_layer_write_permission(@site, @properties).should be_false
      end
    end

    context "can view" do
      it "should return true when user have read permission on layer" do
        @collection.layer_memberships.create( :layer_id => @layer.id, :read => true, :user_id => @user.id, :write => true)
        @user.validate_layer_read_permission(@collection, @properties[0][:code]).should be_true
      end

      it "should return false when user don't have write permission on layer" do
        @user.validate_layer_read_permission(@site, @properties[0][:code]).should be_false
      end
    end
  end
end
