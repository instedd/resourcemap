require 'spec_helper'

describe Membership do
  it { should belong_to :user }
  it { should belong_to :collection }
  it { should have_one :read_sites_permission }
  it { should have_one :write_sites_permission }
  it { should have_one :name_permission }
  it { should have_one :location_permission }

  let(:collection) { Collection.make }
  let(:user) { User.make }
  let(:membership) { collection.memberships.create! :user_id => user.id }
  let(:layer) { collection.layers.make }

  it "should create associations for default permissions on memberships create" do
    membership.location_permission.should be
    membership.name_permission.should be
    membership.location_permission.action.should eq('read')
    membership.name_permission.action.should eq('read')
  end

  it "should delete name_permission when membership is destroyed" do
    membership.set_access(object: 'name', new_action: 'update')
    NamePermission.count.should be(1)
    membership.destroy
    NamePermission.count.should be(0)
  end

  it "should delete location_permission when membership is destroyed" do
    membership.set_access(object: 'location', new_action: 'update')
    LocationPermission.count.should be(1)
    membership.destroy
    LocationPermission.count.should be(0)
  end

  describe "default fields permission" do
    it "should be able to read and update name if user has write permission for name" do
      membership.set_access(object: 'name', new_action: 'update')
      membership.can_read?("name").should be_true
      membership.can_update?("name").should be_true
    end

    it "should be able to read and update location if user has write permission for location" do
      membership.set_access(object: 'name', new_action: 'update')
      membership.can_read?("location").should be_true
      membership.can_update?("location").should be_true
    end

    it "should not be able to set an invalid action_value for name or location" do
      lambda { membership.set_access(object: 'name', new_action: 'invalid')}.should raise_error(StandardError)


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
      user.memberships.create! :collection_id => collection.id
      expect { user.memberships.create!(:collection_id => collection.id) }.to raise_error
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
end
