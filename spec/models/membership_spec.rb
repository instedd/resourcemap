require 'spec_helper'

describe Membership do
  it { should belong_to :user }
  it { should belong_to :collection }
  it { should have_one :read_sites_permission }
  it { should have_one :write_sites_permission }
  it { should have_one :name_permission }
  it { should have_one :location_permission }

  let(:user) { User.make }
  let(:collection) { user.create_collection(Collection.make_unsaved public: true)}
  let(:membership_admin) { collection.memberships.find_by_admin(true)}
  let(:layer) { collection.layers.make }

  let(:member) { User.make }
  let(:membership) { collection.memberships.create! :user_id => member.id }

  it "should delete memberships when the collection is destroyed" do
    collection.destroy
    user.reload
    member.reload
    user.memberships.should eq([])
    member.memberships.should eq([])
  end

  it "should create associations for default permissions on memberships create" do
    membership.location_permission.should be
    membership.name_permission.should be
    membership.location_permission.action.should eq('read')
    membership.name_permission.action.should eq('read')
  end

  it "should delete name_permission when membership is destroyed" do
    membership.set_access(object: 'name', new_action: 'update')
    name_memberships_count = NamePermission.count
    NamePermission.count.should be(name_memberships_count)
    membership.destroy
    NamePermission.count.should be(name_memberships_count - 1)
  end

  it "should delete location_permission when membership is destroyed" do
    membership.set_access(object: 'location', new_action: 'update')
    location_memberships_count = LocationPermission.count
    LocationPermission.count.should be(location_memberships_count)
    membership.destroy
    LocationPermission.count.should be(location_memberships_count -1)
  end

  describe "default fields permission" do
    it "should be able to read and update name if user has write permission for name" do
      membership.set_access(object: 'name', new_action: 'update')
      membership.can_read?("name").should be_true
      membership.can_update?("name").should be_true
    end

    it "should be able to read and update location if user has write permission for location" do
      membership.set_access(object: 'location', new_action: 'update')
      membership.can_read?("location").should be_true
      membership.can_update?("location").should be_true
    end

    it "should not be able to set an invalid action_value for name or location" do
      lambda { membership.set_access(object: 'name', new_action: 'invalid')}.should raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "sites permission" do
    it "should include read permission" do
      read_permission = membership.create_read_sites_permission all_sites: true
      membership.sites_permission.should include(read: read_permission)
    end

    it "should include write permission" do
      write_permission = membership.create_write_sites_permission all_sites: true
      membership.sites_permission.should include(write: write_permission)
    end

    it "should not allow more than one membership per collection and user" do
      yet_another_user = User.make
      yet_another_user.memberships.create! :collection_id => collection.id
      expect { yet_another_user.memberships.create!(:collection_id => collection.id) }.to raise_error
    end

    context "when user is collection admin" do
      it "should allow read for all sites" do
        membership.admin = true
        membership.sites_permission[:read].all_sites.should be true
      end

      it "should allow write for all sites" do
        membership.admin = true
        membership.sites_permission[:write].all_sites.should be true
      end
    end
  end

  describe "export to json" do

    it "should export from a admin membership" do
      json = membership_admin.to_json.with_indifferent_access
      json["user_display_name"].should eq(user.email)
      json["admin"].should eq(true)
      json["layers"].count.should eq(0)
      json["sites"]["read"].should eq(nil)
      json["sites"]["write"].should eq(nil)
      json["name"].should eq("update")
      json["location"].should eq("update")
    end

    it "should export from a member membership" do
      membership.set_access(object: "name", new_action: "update")
      json = membership.to_json.with_indifferent_access
      json["user_display_name"].should eq(member.email)
      json["admin"].should eq(false)
      json["layers"].count.should eq(0)
      json["sites"]["read"].should eq(nil)
      json["sites"]["write"].should eq(nil)
      json["name"].should eq("update")
      json["location"].should eq("read")
    end

    it "should export from a guest membership" do
      guest = User.make is_guest: true
      json = collection.membership_for(guest).to_json.with_indifferent_access
      json["admin"].should eq(false)
      json["layers"].count.should eq(0)
      json["sites"]["read"].should eq(nil)
      json["sites"]["write"].should eq(nil)
      json["name"].should eq("read")
      json["location"].should eq("read")
    end
  end
end
