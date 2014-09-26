require 'spec_helper'

describe Membership::SitesPermissionConcern, :type => :model do
  let(:collection) { Collection.make }
  let(:user) { User.make }
  let!(:membership) { collection.memberships.create! :user_id => user.id }
  let!(:read_sites_permission) { membership.create_read_sites_permission all_sites: true, some_sites: [] }

  it "should find sites permission" do
    expect(membership.find_or_build_sites_permission(:read)).to eq read_sites_permission
  end

  it "should build sites permission" do
    expect(membership.find_or_build_sites_permission(:write)).to be_new_record
  end

  describe "update sites permission" do
    before(:each) do
      membership.update_sites_permission({ read: {all_sites: false}, write: {all_sites: false, some_sites: [{id: 1, name: 'Bayon clinic'}]} })
    end

    it "should change read sites permission" do
      expect(membership.read_sites_permission.all_sites).to eq false
    end

    it "should change write sites permission" do
      permission = membership.write_sites_permission

      expect(permission.all_sites).to eq false
      expect(permission.some_sites).to have(1).items
      expect(permission.some_sites[0]).to eq({id: 1, name: 'Bayon clinic'})
    end

    it "should accept post data from jquery" do
      membership.update_sites_permission({read: {some_sites: {"0" => {"id" => "2", "name" => "Calmette hospital"}}}})
      permission = membership.read_sites_permission

      expect(permission.some_sites).to have(1).items
      expect(permission.some_sites[0]).to eq({"id" => "2", "name" => "Calmette hospital"})
    end
  end
end
