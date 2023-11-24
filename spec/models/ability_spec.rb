require 'spec_helper'
require "cancan/matchers"

describe Ability, :type => :model do
  let!(:admin) { User.make! }
  # The guest user should not be saved, since it will be a dummy user with the is_guest flag in true
  let!(:guest) { User.make is_guest: true}
  let!(:user) { User.make! }
  let!(:member) { User.make! }
  let!(:collection) { admin.create_collection Collection.make! }
  let!(:membership) { collection.memberships.create! :user_id => member.id, admin: false }

  let!(:layer) { Layer.make! collection: collection, user: admin }

  let!(:admin_ability) { Ability.new(admin)}
  let!(:member_ability) { Ability.new(member)}
  let!(:user_ability) { Ability.new(user)}
  let!(:guest_ability) { Ability.new(guest)}

  describe "Collection Abilities" do
    it "Destroy collection" do
      expect(admin_ability).to be_able_to(:destroy, collection)
      expect(member_ability).not_to be_able_to(:destroy, collection)
      expect(user_ability).not_to be_able_to(:destroy, collection)
      expect(guest_ability).not_to be_able_to(:destroy, collection)
    end

    it "Create snapshot" do
      expect(admin_ability).to be_able_to(:create_snapshot, collection)
      expect(member_ability).not_to be_able_to(:create_snapshot, collection)
      expect(user_ability).not_to be_able_to(:create_snapshot, collection)
      expect(guest_ability).not_to be_able_to(:create_snapshot, collection)
    end

    it "Update collection" do
      expect(admin_ability).to be_able_to(:update, collection)
      expect(member_ability).not_to be_able_to(:upate, collection)
      expect(user_ability).not_to be_able_to(:update, collection)
      expect(guest_ability).not_to be_able_to(:update, collection)
    end

    it "Create collection" do
      expect(guest_ability).not_to be_able_to(:create, Collection)
      expect(user_ability).to be_able_to(:create, Collection)
    end

    it "Public Collection Abilities" do
      public_collection = admin.create_collection Collection.make!(anonymous_name_permission: 'read', anonymous_location_permission: 'read')

      expect(user_ability).to be_able_to(:read, public_collection)
      expect(user_ability).not_to be_able_to(:update, public_collection)
    end

    it "Manage snapshots" do

      expect(admin_ability).to be_able_to(:create, (Snapshot.make! collection: collection))
      expect(member_ability).not_to be_able_to(:create, (Snapshot.make! collection: collection))
      expect(user_ability).not_to be_able_to(:create, (Snapshot.make! collection: collection))
      expect(guest_ability).not_to be_able_to(:create, (Snapshot.make! collection: collection))
    end

    it "Members" do
      expect(admin_ability).to be_able_to(:members, collection)
      expect(member_ability).not_to be_able_to(:members, collection)
      expect(user_ability).not_to be_able_to(:members, collection)
      expect(guest_ability).not_to be_able_to(:members, collection)
    end
  end

  describe "Layer Abilities" do
    let!(:new_layer) { Layer.new collection: collection, user: admin }

    it "Create layer" do
      expect(admin_ability).to be_able_to(:create, new_layer)
      expect(member_ability).not_to be_able_to(:create, new_layer)
      expect(user_ability).not_to be_able_to(:create, new_layer)
      expect(guest_ability).not_to be_able_to(:create, new_layer)
    end

    it "Update layer" do
      expect(admin_ability).to be_able_to(:update, layer)
      expect(member_ability).not_to be_able_to(:update, layer)
      expect(user_ability).not_to be_able_to(:update, layer)
      expect(guest_ability).not_to be_able_to(:update, layer)
    end

    it "Destroy layer" do
      expect(admin_ability).to be_able_to(:destroy, layer)
      expect(member_ability).not_to be_able_to(:destroy, layer)
      expect(user_ability).not_to be_able_to(:destroy, layer)
      expect(guest_ability).not_to be_able_to(:destroy, layer)
    end

    it "Set layer order" do
      expect(admin_ability).to be_able_to(:set_order, layer)
      expect(member_ability).not_to be_able_to(:set_order, layer)
      expect(user_ability).not_to be_able_to(:set_order, layer)
      expect(guest_ability).not_to be_able_to(:set_order, layer)
    end

    it "Delete site only for admins" do
      site = collection.sites.make! name: "Site A"

      expect(admin_ability).to be_able_to(:delete, site)
      expect(member_ability).not_to be_able_to(:delete, site)
      expect(user_ability).not_to be_able_to(:delete, site)
      expect(guest_ability).not_to be_able_to(:delete, site)
    end

    describe "Read layer with read permission" do
      let!(:layer_member_read) { LayerMembership.make! layer: layer, membership: membership, read: true }
      let!(:member_ability_with_read_permission) { Ability.new member }

      it { expect(admin_ability).to be_able_to(:read, layer) }
      it { expect(member_ability_with_read_permission).to be_able_to(:read, layer) }
      it { expect(user_ability).not_to be_able_to(:read, layer) }
      it { expect(guest_ability).not_to be_able_to(:read, layer) }
    end

    describe "Should not read layer without read permission" do
      let!(:layer_member_none) { LayerMembership.make! layer: layer, membership: membership, read: false }
      let!(:member_ability_without_read_permission) { Ability.new member }

      it { expect(admin_ability).to be_able_to(:read, layer) }
      it { expect(member_ability_without_read_permission).not_to be_able_to(:read, layer) }
      it { expect(user_ability).not_to be_able_to(:read, layer) }
      it { expect(guest_ability).not_to be_able_to(:read, layer) }
    end

    describe "Should not read layer without read permission if other layer in other collection is visible" do
      let!(:other_collection) { admin.create_collection Collection.make! }
      let!(:other_layer) { Layer.make! collection: other_collection, user: admin }

      let!(:layer_member_read_in_other_collection) { LayerMembership.make! layer: other_layer, membership: membership, read: true }

      let!(:layer_member_none) { LayerMembership.make! layer: layer, membership: membership, read: false }

      let!(:membership_two_different_permissions) { Ability.new member }

      it { expect(admin_ability).to be_able_to(:read, layer) }
      it { expect(membership_two_different_permissions).not_to be_able_to(:read, layer) }
      it { expect(user_ability).not_to be_able_to(:read, layer) }
      it { expect(guest_ability).not_to be_able_to(:read, layer) }
    end

    describe "Should read layers if it has anonymous_user read permission" do
      let!(:public_collection) { admin.create_collection Collection.make!(anonymous_name_permission: 'read', anonymous_location_permission: 'read') }
      let!(:layer_in_public_collection) { Layer.make! collection: public_collection, user: admin, anonymous_user_permission: 'read' }

      it { expect(admin_ability).to be_able_to(:read, layer_in_public_collection) }
      it { expect(user_ability).to be_able_to(:read, layer_in_public_collection) }
      it { expect(guest_ability).to be_able_to(:read, layer_in_public_collection) }
    end

    # Issue #574
    describe "Should not read duplicated layers for guest user if the collection is public" do
      let!(:public_collection) { admin.create_collection Collection.make!(anonymous_name_permission: 'read',
        anonymous_location_permission: 'read')}
      # Public collection with more than one membership were given duplicated results.
      let!(:membership) { public_collection.memberships.create! :user_id => member.id, admin: false }

      let!(:layer_in_public_collection) { Layer.make! collection: public_collection, user: admin, anonymous_user_permission: 'read' }

      it { expect(public_collection.layers.accessible_by(guest_ability).count).to eq(1) }
    end

  end

  describe "Site-field Abilities for layers" do

    context "registered users" do
      let!(:field) { Field::TextField.make! collection: collection, layer: layer }
      let!(:site) { collection.sites.make! }

      describe "admin" do
        it { expect(admin_ability).to be_able_to(:update_site_property, field, site) }
        it { expect(admin_ability).to be_able_to(:read_site_property, field, site) }
      end

      describe "member with none permission" do
        let!(:layer_member_none) { LayerMembership.make! layer: layer, membership: membership, read: false }
        let!(:member_ability_without_read_permission) { Ability.new member }

        it { expect(member_ability_without_read_permission).not_to be_able_to(:update_site_property, field, site) }
        it { expect(member_ability_without_read_permission).not_to be_able_to(:read_site_property, field, site) }
      end

      describe "member with read permission" do
        let!(:layer_member_none) { LayerMembership.make! layer: layer, membership: membership, read: true }
        let!(:member_ability_with_read_permission) { Ability.new member }

        it { expect(member_ability_with_read_permission).not_to be_able_to(:update_site_property, field, site) }
        it { expect(member_ability_with_read_permission).to be_able_to(:read_site_property, field, site) }
      end

      describe "member with write permission" do
        let!(:layer_member_none) { LayerMembership.make! layer: layer, membership: membership, write: true }
        let!(:member_ability_with_write_permission) { Ability.new member }

        it { expect(member_ability_with_write_permission).to be_able_to(:update_site_property, field, site) }
        it { expect(member_ability_with_write_permission).to be_able_to(:read_site_property, field, site) }
      end

      context "Site creation" do
        it "can't create sites if it doesn't have write permissions" do
          membership.set_access({object: 'name', new_action: 'read'})
          membership.set_access({object: 'location', new_action: 'read'})

          expect(member_ability).not_to be_able_to(:create_site, collection)
        end

        it "can't create sites if it doesn't have both write permissions" do
          membership.set_access({object: 'name', new_action: 'update'})
          membership.set_access({object: 'location', new_action: 'read'})

          expect(member_ability).not_to be_able_to(:create_site, collection)
        end

        it "can't create sites if it doesn't have both write permissions" do
          membership.set_access({object: 'name', new_action: 'read'})
          membership.set_access({object: 'location', new_action: 'update'})

          expect(member_ability).not_to be_able_to(:create_site, collection)
        end

        it "can create sites if it has both write permissions" do
          membership.set_access({object: 'name', new_action: 'update'})
          membership.set_access({object: 'location', new_action: 'update'})

          expect(member_ability).to be_able_to(:create_site, collection)
        end
      end
    end

    describe "guest user should not be able to update site property" do
      let!(:public_collection) { admin.create_collection Collection.make!(anonymous_name_permission: 'read', anonymous_location_permission: 'read') }
      let!(:layer_in_public_collection) { Layer.make! collection: public_collection, user: admin }
      let!(:field_in_public_collection) { Field::TextField.make! collection: public_collection, layer: layer_in_public_collection }
      let!(:site_in_public_collection) { public_collection.sites.make! }

      it { expect(guest_ability).not_to be_able_to(:update_site_property, field_in_public_collection, site_in_public_collection) }
    end
  end
end
