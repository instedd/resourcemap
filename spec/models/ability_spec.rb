require 'spec_helper'
require "cancan/matchers"

describe Ability do
  let!(:admin) { User.make }
  # The guest user should not be saved, since it will be a dummy user with the is_guest flag in true
  let!(:guest) { User.make_unsaved is_guest: true}
  let!(:user) { User.make }
  let!(:member) { User.make }
  let!(:collection) { admin.create_collection Collection.make }
  let!(:membership) { collection.memberships.create! :user_id => member.id, admin: false }

  let!(:layer) { Layer.make collection: collection, user: admin }

  let!(:admin_ability) { Ability.new(admin)}
  let!(:member_ability) { Ability.new(member)}
  let!(:user_ability) { Ability.new(user)}
  let!(:guest_ability) { Ability.new(guest)}


  describe "Collection Abilities" do

    it "Destroy collection" do
      admin_ability.should be_able_to(:destroy, collection)
      member_ability.should_not be_able_to(:destroy, collection)
      user_ability.should_not be_able_to(:destroy, collection)
      guest_ability.should_not be_able_to(:destroy, collection)
    end

    it "Create snapshot" do
      admin_ability.should be_able_to(:create_snapshot, collection)
      member_ability.should_not be_able_to(:create_snapshot, collection)
      user_ability.should_not be_able_to(:create_snapshot, collection)
      guest_ability.should_not be_able_to(:create_snapshot, collection)
    end

    it "Update collection" do
      admin_ability.should be_able_to(:update, collection)
      member_ability.should_not be_able_to(:upate, collection)
      user_ability.should_not be_able_to(:update, collection)
      guest_ability.should_not be_able_to(:update, collection)
    end

    it "Create collection" do
      guest_ability.should_not be_able_to(:create, Collection)
      user_ability.should be_able_to(:create, Collection)
    end

    it "Public Collection Abilities" do
      public_collection = admin.create_collection Collection.make public: true

      user_ability.should be_able_to(:read, public_collection)
      user_ability.should_not be_able_to(:update, public_collection)

    end

    it "Manage snapshots" do

      admin_ability.should be_able_to(:create, (Snapshot.make collection: collection))
      member_ability.should_not be_able_to(:create, (Snapshot.make collection: collection))
      user_ability.should_not be_able_to(:create, (Snapshot.make collection: collection))
      guest_ability.should_not be_able_to(:create, (Snapshot.make collection: collection))
    end

    it "Members" do
      admin_ability.should be_able_to(:members, collection)
      member_ability.should_not be_able_to(:members, collection)
      user_ability.should_not be_able_to(:members, collection)
      guest_ability.should_not be_able_to(:members, collection)
    end
  end

  describe "Layer Abilities" do
    let!(:new_layer) { Layer.new collection: collection, user: admin }

    it "Create layer" do
      admin_ability.should be_able_to(:create, new_layer)
      member_ability.should_not be_able_to(:create, new_layer)
      user_ability.should_not be_able_to(:create, new_layer)
      guest_ability.should_not be_able_to(:create, new_layer)
    end

    it "Update layer" do
      admin_ability.should be_able_to(:update, layer)
      member_ability.should_not be_able_to(:update, layer)
      user_ability.should_not be_able_to(:update, layer)
      guest_ability.should_not be_able_to(:update, layer)
    end

    it "Destroy layer" do
      admin_ability.should be_able_to(:destroy, layer)
      member_ability.should_not be_able_to(:destroy, layer)
      user_ability.should_not be_able_to(:destroy, layer)
      guest_ability.should_not be_able_to(:destroy, layer)
    end

    it "Set layer order" do
      admin_ability.should be_able_to(:set_order, layer)
      member_ability.should_not be_able_to(:set_order, layer)
      user_ability.should_not be_able_to(:set_order, layer)
      guest_ability.should_not be_able_to(:set_order, layer)
    end

    describe "Read layer with read permission" do
      let!(:layer_member_read) { LayerMembership.make layer: layer, membership: membership, read: true }
      let!(:member_ability_with_read_permission) { Ability.new member }

      it { admin_ability.should be_able_to(:read, layer) }
      it { member_ability_with_read_permission.should be_able_to(:read, layer) }
      it { user_ability.should_not be_able_to(:read, layer) }
      it { guest_ability.should_not be_able_to(:read, layer) }
    end

    describe "Should not read layer without read permission" do
      let!(:layer_member_none) { LayerMembership.make layer: layer, membership: membership, read: false }
      let!(:member_ability_without_read_permission) { Ability.new member }

      it { admin_ability.should be_able_to(:read, layer) }
      it { member_ability_without_read_permission.should_not be_able_to(:read, layer) }
      it { user_ability.should_not be_able_to(:read, layer) }
      it { guest_ability.should_not be_able_to(:read, layer) }
    end

    describe "Should not read layer without read permission if other layer in other collection is visible" do
      let!(:other_collection) { admin.create_collection Collection.make }
      let!(:other_layer) { Layer.make collection: other_collection, user: admin }

      let!(:layer_member_read_in_other_collection) { LayerMembership.make layer: other_layer, membership: membership, read: true }

      let!(:layer_member_none) { LayerMembership.make layer: layer, membership: membership, read: false }

      let!(:membership_two_different_permissions) { Ability.new member }

      it { admin_ability.should be_able_to(:read, layer) }
      it { membership_two_different_permissions.should_not be_able_to(:read, layer) }
      it { user_ability.should_not be_able_to(:read, layer) }
      it { guest_ability.should_not be_able_to(:read, layer) }
    end

    describe "Should read layers if the collection is public" do
      let!(:public_collection) { admin.create_collection Collection.make public: true}
      let!(:layer_in_public_collection) { Layer.make collection: public_collection, user: admin }

      it { admin_ability.should be_able_to(:read, layer_in_public_collection) }
      it { user_ability.should_not be_able_to(:read, layer_in_public_collection) }
      it { guest_ability.should be_able_to(:read, layer_in_public_collection) }
    end

    # Issue #574
    describe "Should not read duplicated layers for guest user if the collection is public" do
      let!(:public_collection) { admin.create_collection Collection.make public: true}
      # Public collection with more than one membership were given duplicated results.
      let!(:membership) { public_collection.memberships.create! :user_id => member.id, admin: false }

      let!(:layer_in_public_collection) { Layer.make collection: public_collection, user: admin }

      it { public_collection.layers.accessible_by(guest_ability).count.should eq(1) }
    end

  end

  describe "Site-field Abilities for layers" do

    context "registered users" do
      let!(:field) { Field::TextField.make collection: collection, layer: layer }
      let!(:site) { collection.sites.make }

      describe "admin" do
        it { admin_ability.should be_able_to(:update_site_property, field, site) }
        it { admin_ability.should be_able_to(:read_site_property, field, site) }
      end

      describe "member with none permission" do
        let!(:layer_member_none) { LayerMembership.make layer: layer, membership: membership, read: false }
        let!(:member_ability_without_read_permission) { Ability.new member }

        it { member_ability_without_read_permission.should_not be_able_to(:update_site_property, field, site) }
        it { member_ability_without_read_permission.should_not be_able_to(:read_site_property, field, site) }
      end

      describe "member with read permission" do
        let!(:layer_member_none) { LayerMembership.make layer: layer, membership: membership, read: true }
        let!(:member_ability_with_read_permission) { Ability.new member }

        it { member_ability_with_read_permission.should_not be_able_to(:update_site_property, field, site) }
        it { member_ability_with_read_permission.should be_able_to(:read_site_property, field, site) }
      end

      describe "member with write permission" do
        let!(:layer_member_none) { LayerMembership.make layer: layer, membership: membership, write: true }
        let!(:member_ability_with_write_permission) { Ability.new member }

        it { member_ability_with_write_permission.should be_able_to(:update_site_property, field, site) }
        it { member_ability_with_write_permission.should be_able_to(:read_site_property, field, site) }
      end
    end

    describe "guest user should not be able to update site property" do
      let!(:public_collection) { admin.create_collection Collection.make public: true}
      let!(:layer_in_public_collection) { Layer.make collection: public_collection, user: admin }
      let!(:field_in_public_collection) { Field::TextField.make collection: public_collection, layer: layer_in_public_collection }
      let!(:site_in_public_collection) { public_collection.sites.make }

      it { guest_ability.should_not be_able_to(:update_site_property, field_in_public_collection, site_in_public_collection) }
    end
  end

end
