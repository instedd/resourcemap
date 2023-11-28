require 'spec_helper'

describe User, :type => :model do
  # it { is_expected.to have_many :memberships }
  # it { is_expected.to have_many :collections }

  it "should be confirmed" do
    user = User.make confirmed_at: nil
    expect(user.confirmed?).to be_falsey
    user.confirm
    expect(user.reload.confirmed?).to be_truthy
  end

  it "creates a collection" do
    user = User.make
    collection = Collection.make_unsaved
    expect(user.create_collection(collection)).to eq(collection)
    expect(user.collections).to eq([collection])
    expect(user.memberships.first).to be_admin
  end

  it "fails to create a collection if invalid" do
    user = User.make
    collection = Collection.make_unsaved
    collection.name = nil
    expect(user.create_collection(collection)).to be_falsey
    expect(user.collections).to be_empty
  end

  context "admins?" do
    let(:user) { User.make }
    let(:collection) { user.create_collection Collection.make_unsaved }

    it "admins a collection" do
      expect(user.admins?(collection)).to be_truthy
    end

    it "doesn't admin a collection if belongs but not admin" do
      user2 = User.make
      user2.memberships.create! :collection_id => collection.id
      expect(user2.admins?(collection)).to be_falsey
    end

    it "doesn't admin a collection if doesn't belong" do
      expect(User.make.admins?(collection)).to be_falsey
    end

    it "creates a layer" do
      data = {
        name: "A layer",
        ord: 1,
        fields_attributes: [{name: "A field", code: "afield", kind: "text", ord: 1}]
      }

      l = user.create_layer_for(collection, data)
      expect(l).to be_an_instance_of Layer
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

      expect(user.activities.length).to eq(1)
    end

    it "doesn't return activities for user membership" do
      user2 = User.make

      Activity.make collection_id: collection.id, user_id: user.id, item_type: 'collection', action: 'created'

      expect(user2.activities.length).to eq(0)
    end
  end

  describe "Permission" do
    before(:each) do
      @user1  = User.make
      @user = User.create(:email => "demo@instedd.org", :password => "123456", :phone_number => "855123456789")
      @collection = Collection.make
      @membership = @collection.memberships.create(:user => @user, :admin => false)
      @site  = @collection.sites.make
      @layer = @collection.layers.make(:name => "health center")
      @properties =[{:code=>"AB", :value=>"26"}]
      @field = Field.create(:collection_id => @collection.id, :layer_id => @layer.id, :code => "AB", :ord => 1, :kind => "numeric")
    end

    it "should be able to view and update layer" do
      @membership.layer_memberships.create( :layer_id => @layer.id, :read => true, :write => true)
      Field::NumericField.create :collection_id => @collection.id, :layer_id => @layer.id, :code => "AB", :ord => 1
      expect(@user.can_view?(@collection, @properties[0][:code])).to be_truthy
      expect(@user.can_update?(@site, @properties)).to be_truthy
    end

    context "can update" do
      it "should return true when user have write permission on layer" do
        @membership.layer_memberships.create(:layer_id => @layer.id, :read => true, :write => true)
        expect(@user.validate_layer_write_permission(@site, @properties)).to be_truthy
      end

      it "should return false when user don't have write permission on layer" do
        expect(@user.validate_layer_write_permission(@site, @properties)).to be_falsey
      end

      it "should return true when two field have the same code 'AB' but difference collection_id" do
        @collection1 = Collection.make
        @layer1 = @collection1.layers.make :name => "school"
        @field1 = Field.create(:collection_id => @collection1.id, :layer_id => @layer1.id, :code => "AB", :ord => 1, :kind => "numeric")
        @site1  = @collection1.sites.make
        membership = @collection1.memberships.create(:user => @user, :admin => false)
        membership.layer_memberships.create(:layer_id => @layer1.id, :read => true, :write => true, :membership_id => membership.id)
        expect(@user.validate_layer_write_permission(@site1, @properties)).to be_truthy
      end
    end

    context "can view" do
      it "should return true when user have read permission on layer" do
        @membership.layer_memberships.create(:layer_id => @layer.id, :read => true, :write => true)
        expect(@user.validate_layer_read_permission(@collection, @properties[0][:code])).to be_truthy
      end

      it "should return false when user don't have write permission on layer" do
        expect(@user.validate_layer_read_permission(@site, @properties[0][:code])).to be_falsey
      end
    end
  end

  it "should encrypt all users password" do
    User.connection.execute "INSERT INTO `users` (`id`, `email`, `encrypted_password`, `created_at`, `updated_at`) VALUES (22, 'userspec@example.com', 'bar123', '#{Time.now.utc.to_s(:db)}', '#{Time.now.utc.to_s(:db)}')"
    User.encrypt_users_password
    expect(User.first.encrypted_password).not_to eq('bar123')
  end

  describe 'gateway' do
    let(:user_1){ User.make }
    let!(:gateway) { user_1.channels.make name: 'default', ticket_code: '1234', basic_setup: true}

    it 'should return gateway under user' do
      expect(user_1.get_gateway).to eq gateway
    end
  end

  # This bug only happens when de collections are deleted using "delete" or for old memberships
  # since if they are destroyed all its memberships are also destroyed
  it "should not get memberships for deleted collections" do
    user = User.make
    collection = user.create_collection Collection.make
    collection.delete
    user.reload
    expect(user.collections_i_admin).to eq []
  end

  describe 'telemetry' do
    it 'should touch lifespan on create' do
      user = User.make_unsaved

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user)

      user.save
    end

    it 'should touch lifespan on update' do
      user = User.make
      user.touch

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user)

      user.save
    end

    it 'should touch lifespan on destroy' do
      user = User.make

      expect(Telemetry::Lifespan).to receive(:touch_user).with(user)

      user.destroy
    end
  end
end
