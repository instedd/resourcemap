require 'spec_helper'
describe Collection, :type => :model do
  # it { is_expected.to have_many :memberships }
  # it { is_expected.to have_many :users }
  # it { is_expected.to have_many :layers }
  # it { is_expected.to have_many :fields }
  # it { is_expected.to have_many :thresholds }

  let(:user) { User.make }
  let(:collection) { user.create_collection Collection.make_unsaved(anonymous_name_permission: 'read', anonymous_location_permission: 'read')}
  let(:collection2) { user.create_collection Collection.make_unsaved(anonymous_name_permission: 'none', anonymous_location_permission: 'none')}
  let!(:layer) { collection.layers.make user: user, fields_attributes: [{kind: 'numeric', code: 'foo', name: 'Foo', ord: 1}] }
  let(:field) { layer.fields.first }

  context "max value" do
    it "gets max value for property that exists" do
      collection.sites.make :properties => {field.es_code => 10}
      collection.sites.make :properties => {field.es_code => 20}, :lat => nil, :lng => nil
      collection.sites.make :properties => {field.es_code => 5}

      expect(collection.max_value_of_property(field.es_code)).to eq(20)
    end
  end

  describe "thresholds test" do
    let(:site) { collection.sites.make properties: {field.es_code => 9}}
    it "should return false when there is no threshold" do
      expect(collection.thresholds_test(site)).to be_falsey
    end

    it "should return false when no threshold is hit" do
      collection.thresholds.make is_all_site: true, conditions: [ field: 1, op: :gt, value: 10 ]
      expect(collection.thresholds_test(site)).to be_falsey
    end

    it "should return true when threshold 1 is hit" do
      collection.thresholds.make is_all_site: false, sites: [{"id" => site.id}], conditions: [ field: field.es_code, op: :lt, value: 10 ]
      expect(collection.thresholds_test(site)).to be_truthy
    end

    it "should return true when threshold 2 is hit" do
      collection.thresholds.make sites: [{"id" => site.id}], conditions: [ field: field.es_code, op: :gt, value: 10 ]
      collection.thresholds.make sites: [{"id" => site.id}], conditions: [ field: field.es_code, op: :eq, value: 9 ]
      expect(collection.thresholds_test(site)).to be_truthy
    end

    describe "multiple thresholds test" do
      let(:site_2) { collection.sites.make properties: {field.es_code => 25}}

      it "should evaluate second threshold" do
        collection.thresholds.make is_all_site: false, conditions: [ {field: field.es_code, op: :gt, value: 10} ], sites: [{ "id" => site.id }]
        collection.thresholds.make is_all_site: false, conditions: [ {field: field.es_code, op: :gt, value: 20} ], sites: [{ "id" => site_2.id }]
        expect(collection.thresholds_test(site_2)).to be_truthy
      end
    end
  end

  describe "SMS query" do
    describe "Operator parser" do
      it "should return operator for search class" do
        expect(collection.operator_parser(">")).to eq("gt")
        expect(collection.operator_parser("<")).to eq("lt")
        expect(collection.operator_parser("=>")).to eq("gte")
        expect(collection.operator_parser("=<")).to eq("lte")
        expect(collection.operator_parser(">=")).to eq("gte")
        expect(collection.operator_parser("<=")).to eq("lte")
      end
    end
  end

  describe "History" do
    it "destroys the User Snapshots when destroying a collection" do
      collection.snapshots.create! date: Time.now, name: 'snp1'
      UserSnapshot.for(user, collection).save

      expect(UserSnapshot.count).to eq(1)

      collection.destroy

      expect(UserSnapshot.count).to eq(0)
      expect(Collection.count).to eq(0)
    end

    it "should obtain snapshot for user if user_snapshot exists" do
      user = User.make
      snp_1 = collection.snapshots.create! date: Time.now, name: 'snp1'
      snp_1.user_snapshots.create! user: user

      snp_2 = collection.snapshots.create! date: Time.now, name: 'snp2'
      snp_2.user_snapshots.create! user: User.make

      snapshot = collection.snapshot_for(user)
      expect(snapshot.name).to eq('snp1')
    end

    it "should obtain nil snapshot_name for user if user_snapshot does not exists" do
      snp_1 = collection.snapshots.create! date: Time.now, name: 'snp1'
      snp_1.user_snapshots.create! user: User.make

      user = User.make
      snapshot = collection.snapshot_for(user)
      expect(snapshot).to be_nil
    end
  end

  describe "memberships" do
    it "should obtain membership for collection admin" do
      membership = collection.membership_for(user)
      expect(membership.admin).to be(true)
    end

    it "should obtain membership for collection user" do
      member = User.make
      membership_for_member = collection.memberships.create! :user_id => member.id, admin: false
      membership = collection.membership_for(member)
      expect(membership.admin).to be(false)
    end

    it "should obtain membership if collection has anonymous read permission and user is not member " do
      non_member = User.make
      membership = collection.membership_for(non_member)
      expect(membership).not_to be_nil
    end

    it "should not obtain membership if collection doesn't have anonymous read permission and useris not member" do
      non_member = User.make
      membership = collection2.membership_for(non_member)
      expect(membership).to be_nil
    end

    it "should obtain dummy membership for guest user" do
      guest = User.make
      guest.is_guest = true
      membership = collection.membership_for(guest)
      expect(membership.admin).to be(false)
    end
  end

  describe "plugins" do
    # will fixe as soon as possible
    skip do
      it "should set plugins by names" do
        collection.selected_plugins = ['plugin_1', 'plugin_2']
        expect(collection.plugins).to eq({'plugin_1' => {}, 'plugin_2' => {}})
      end

      it "should skip blank plugin name when setting plugins" do
        collection.selected_plugins = ["", 'plugin_1', ""]
        expect(collection.plugins).to eq({'plugin_1' => {}})
      end
    end
  end

  describe 'gateway' do
    let(:admin_user) { User.make }
    let(:collection_1) { admin_user.create_collection Collection.make name: 'test'}
    let!(:gateway) { admin_user.channels.make name: 'default', basic_setup: true, ticket_code: '2222'  }

    it 'should return user_owner of collection' do
      expect(collection_1.get_user_owner).to eq admin_user
    end

    it 'should return gateway under user_owner' do
      expect(collection_1.get_gateway_under_user_owner).to eq gateway
    end
  end

  describe 'es_codes_by_field_code' do
    let(:collection_a) { user.create_collection Collection.make_unsaved }
    let(:layer_a) { collection_a.layers.make user: user }

    let!(:field_a) { layer_a.text_fields.make code: 'A', name: 'A', ord: 1 }
    let!(:field_b) { layer_a.text_fields.make code: 'B', name: 'B', ord: 2 }
    let!(:field_c) { layer_a.text_fields.make code: 'C', name: 'C', ord: 3 }
    let!(:field_d) { layer_a.text_fields.make code: 'D', name: 'D', ord: 4 }

    it 'returns a dict of es_codes by field_code' do
      dict = collection_a.es_codes_by_field_code

      expect(dict['A']).to eq(field_a.es_code)
      expect(dict['B']).to eq(field_b.es_code)
      expect(dict['C']).to eq(field_c.es_code)
      expect(dict['D']).to eq(field_d.es_code)
    end
  end

  describe 'visibility by user for' do
    # Layers are tested in layer_access_spec
    context 'fields' do

      it "should be visible for collection owner" do
        expect(collection.visible_fields_for(user, {})).to eq([field])
      end

      it "should not be visible for unrelated user" do
        new_user = User.make
        expect(collection.visible_fields_for(new_user, {})).to be_empty
      end

      # Test for https://github.com/instedd/resourcemap/issues/735
      it "should not create duplicates with multiple users when anonymous permissions are given for a layer" do
        layer.anonymous_user_permission = 'read'
        layer.save!

        new_user = User.make
        membership = collection.memberships.create user: new_user
        membership.set_layer_access :verb => :read, :access => true, :layer_id => layer.id
        expect(collection.visible_fields_for(user, {})).to eq([field])
      end
    end
  end

  describe 'visibility by user for' do
    # Layers are tested in layer_access_spec
    context 'fields' do
      before(:each) { layer }

      it "should be visible for collection owner" do
        expect(collection.visible_fields_for(user, {})).to eq([field])
      end

      it "should not be visible for unrelated user" do
        new_user = User.make
        expect(collection.visible_fields_for(new_user, {})).to be_empty
      end

      it "should not create duplicates with multiple users" do
        new_user = User.make
        membership = collection.memberships.create user: new_user
        membership.set_layer_access :verb => :read, :access => true, :layer_id => layer.id
        expect(collection.visible_fields_for(user, {})).to eq([field])
      end

      it "should not create duplicates when annonymous user has read permissions" do
        expect(collection.visible_fields_for(user, {})).to eq([field])
      end
    end
  end

  describe 'telemetry' do
    it 'should touch lifespan on create' do
      collection = Collection.make_unsaved

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      collection.save
    end

    it 'should touch lifespan on update' do
      collection = Collection.make
      collection.touch

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      collection.save
    end

    it 'should touch lifespan on destroy' do
      collection = Collection.make

      expect(Telemetry::Lifespan).to receive(:touch_collection).with(collection)

      collection.destroy
    end
  end
end
