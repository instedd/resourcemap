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
      @field = Field.create(:collection_id => @collection.id, :layer_id => @layer.id, :code => "AB", :ord => 1, :kind => "numeric")
    end

    it "should be able to view and update layer" do
      @collection.memberships.create(:user => @user, :admin => false)
      @collection.layer_memberships.create( :layer_id => @layer.id, :read => true, :user_id => @user.id, :write => true)
      Field::NumericField.create :collection_id => @collection.id, :layer_id => @layer.id, :code => "AB", :ord => 1
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

      it "should return true when two field have the same code 'AB' but difference collection_id" do
        @collection1 = Collection.make
        @layer1 = @collection1.layers.create(:name => "school")
        @field1 = Field.create(:collection_id => @collection1.id, :layer_id => @layer1.id, :code => "AB", :ord => 1, :kind => "numeric")
        @site1  = @collection1.sites.make
        @collection1.layer_memberships.create( :layer_id => @layer1.id, :read => true, :user_id => @user.id, :write => true)
        @user.validate_layer_write_permission(@site1, @properties).should be_true
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

  it "should encrypt all users password" do
    User.connection.execute "INSERT INTO `users` (`id`, `email`, `encrypted_password`) VALUES (22, 'foo@example.com', 'bar123')"
    User.encrypt_users_password
    User.first.encrypted_password.should_not == 'bar123'
  end

  describe 'gateway' do 
    let(:user_1){ User.make }
    let!(:gateway) { user_1.channels.make name: 'default', ticket_code: '1234', basic_setup: true}

    it 'should return gateway under user' do
      user_1.get_gateway.should eq gateway 
    end
  end
end
