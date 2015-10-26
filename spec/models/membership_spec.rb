require 'spec_helper'

describe Membership, :type => :model do
  include_examples 'collection lifespan', described_class
  include_examples 'user lifespan', described_class

  it { is_expected.to belong_to :user }
  it { is_expected.to belong_to :collection }
  it { is_expected.to have_one :read_sites_permission }
  it { is_expected.to have_one :write_sites_permission }
  it { is_expected.to have_one :name_permission }
  it { is_expected.to have_one :location_permission }

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make_unsaved(anonymous_name_permission: 'read',
    anonymous_location_permission: 'read') )}
  let(:membership_admin) { collection.memberships.find_by_admin(true)}
  let(:layer) { collection.layers.make }

  let(:member) { User.make }
  let(:membership) { collection.memberships.create! :user_id => member.id }

  it "should delete memberships when the collection is destroyed" do
    collection.destroy
    user.reload
    member.reload
    expect(user.memberships).to eq([])
    expect(member.memberships).to eq([])
  end

  it "should create associations for default permissions on memberships create" do
    expect(membership.location_permission).to be
    expect(membership.name_permission).to be
    expect(membership.location_permission.action).to eq('read')
    expect(membership.name_permission.action).to eq('read')
  end

  it "should delete name_permission when membership is destroyed" do
    membership.set_access(object: 'name', new_action: 'update')
    name_memberships_count = NamePermission.count
    expect(NamePermission.count).to be(name_memberships_count)
    membership.destroy
    expect(NamePermission.count).to be(name_memberships_count - 1)
  end

  it "should delete location_permission when membership is destroyed" do
    membership.set_access(object: 'location', new_action: 'update')
    location_memberships_count = LocationPermission.count
    expect(LocationPermission.count).to be(location_memberships_count)
    membership.destroy
    expect(LocationPermission.count).to be(location_memberships_count -1)
  end

  describe "default fields permission" do
    it "should be able to read and update name if user has write permission for name" do
      membership.set_access(object: 'name', new_action: 'update')
      expect(membership.can_read?("name")).to be_truthy
      expect(membership.can_update?("name")).to be_truthy
    end

    it "should be able to read and update location if user has write permission for location" do
      membership.set_access(object: 'location', new_action: 'update')
      expect(membership.can_read?("location")).to be_truthy
      expect(membership.can_update?("location")).to be_truthy
    end

    it "should not be able to set an invalid action_value for name or location" do
      expect { membership.set_access(object: 'name', new_action: 'invalid')}.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "sites permission" do
    it "should include read permission" do
      read_permission = membership.create_read_sites_permission all_sites: true
      expect(membership.sites_permission).to include(read: read_permission)
    end

    it "should include write permission" do
      write_permission = membership.create_write_sites_permission all_sites: true
      expect(membership.sites_permission).to include(write: write_permission)
    end

    it "should not allow more than one membership per collection and user" do
      yet_another_user = User.make
      yet_another_user.memberships.create! :collection_id => collection.id
      expect { yet_another_user.memberships.create!(:collection_id => collection.id) }.to raise_error
    end

    context "when user is collection admin" do
      it "should allow read for all sites" do
        membership.admin = true
        expect(membership.sites_permission[:read].all_sites).to be true
      end

      it "should allow write for all sites" do
        membership.admin = true
        expect(membership.sites_permission[:write].all_sites).to be true
      end
    end
  end

  describe "export to json" do

    it "should export from a admin membership" do
      json = membership_admin.as_json.with_indifferent_access
      expect(json["user_id"]).to eq(user.id)
      expect(json["user_display_name"]).to eq(user.email)
      expect(json["admin"]).to eq(true)
      expect(json["layers"].count).to eq(0)
      expect(json["sites"]["read"]).to eq(nil)
      expect(json["sites"]["write"]).to eq(nil)
      expect(json["name"]).to eq("update")
      expect(json["location"]).to eq("update")
    end

    it "should export from a member membership" do
      membership.set_access(object: "name", new_action: "update")
      json = membership.as_json.with_indifferent_access
      expect(json["user_id"]).to eq(member.id)
      expect(json["user_display_name"]).to eq(member.email)
      expect(json["admin"]).to eq(false)
      expect(json["layers"].count).to eq(0)
      expect(json["sites"]["read"]).to eq(nil)
      expect(json["sites"]["write"]).to eq(nil)
      expect(json["name"]).to eq("update")
      expect(json["location"]).to eq("read")
    end

    it "should export from a guest membership" do
      guest = User.make is_guest: true
      json = collection.membership_for(guest).as_json.with_indifferent_access
      expect(json["admin"]).to eq(false)
      expect(json["layers"].count).to eq(0)
      expect(json["sites"]["read"]).to eq(nil)
      expect(json["sites"]["write"]).to eq(nil)
      expect(json["name"]).to eq("read")
      expect(json["location"]).to eq("read")
    end
  end

  context "layer access" do
    let(:user2) { User.make }
    let(:membership2) { collection.memberships.create! :user_id => user2.id }

    context "when no access already exists" do
      it "grants read access to layer" do
        membership2.set_layer_access :verb => :read, :access => true, :layer_id => layer.id

        lms = LayerMembership.all
        expect(lms.length).to eq(1)
        expect(lms[0].membership_id).to eq(membership2.id)
        expect(lms[0].layer_id).to eq(layer.id)
        expect(lms[0].read).to be_truthy
        expect(lms[0].write).to be_falsey
      end
    end

    context "when access to layer already exists" do
      it "grants read access and denies write access" do
        LayerMembership.create! :layer_id => layer.id, :membership => membership2, :read => false, :write => true

        membership2.activity_user = user
        membership2.set_layer_access :verb => :read, :access => true, :layer_id => layer.id

        lms = LayerMembership.all
        expect(lms.length).to eq(1)
        expect(lms[0].layer_id).to eq(layer.id)
        expect(lms[0].membership_id).to eq(membership2.id)
        expect(lms[0].read).to be_truthy
        expect(lms[0].write).to be_falsey
      end

      it "revokes read access" do
        LayerMembership.create! :layer_id => layer.id, :membership => membership2, :read => true, :write => false

        membership2.set_layer_access :verb => :read, :access => false, :layer_id => layer.id

        expect(LayerMembership.exists?).to be_falsey
      end
    end
  end

  context "on destroy" do
    let(:collection2) { Collection.make }
    let(:membership2) { collection2.memberships.create! :user_id => user.id }
    it "destroys collection layer memberships" do

      membership2.layer_memberships.create! :layer_id => layer.id, :read => true, :write => true

      membership2.destroy

      expect(collection2.memberships.exists?).to be_falsey
      expect(layer.layer_memberships.exists?).to be_falsey
    end
  end
end
