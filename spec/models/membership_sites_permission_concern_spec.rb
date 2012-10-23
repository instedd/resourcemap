require 'spec_helper'

describe Membership::SitesPermissionConcern do
  let!(:collection) { Collection.make }
  let!(:user) { User.make }
  let!(:membership) { collection.memberships.create! :user_id => user.id }
  let!(:read_sites_permission) { membership.create_read_sites_permission all_sites: true, some_sites: [] }

  it "should find sites permission" do
    membership.find_or_build_sites_permission(:read).should eq read_sites_permission
  end

  it "should build sites permission" do
    membership.find_or_build_sites_permission(:write).should be_new_record
  end

  describe "update sites permission" do
    before(:each) do
      membership.update_sites_permission({ read: {all_sites: false}, write: {all_sites: false, some_sites: [{id: 1, name: 'Bayon clinic'}]} })
    end

    it "should change read sites permission" do
      membership.read_sites_permission.all_sites.should eq false
    end

    it "should change write sites permission" do
      permission = membership.write_sites_permission

      permission.all_sites.should eq false
      permission.some_sites.should have(1).items
      permission.some_sites[0].should eq({id: 1, name: 'Bayon clinic'})
    end

    it "should accept post data from jquery" do
      membership.update_sites_permission({read: {some_sites: {"0" => {"id" => "2", "name" => "Calmette hospital"}}}})
      permission = membership.read_sites_permission

      permission.some_sites.should have(1).items
      permission.some_sites[0].should eq({"id" => "2", "name" => "Calmette hospital"})
    end
  end
end
