class AddMembershipIdToLayerMembership < ActiveRecord::Migration

  def up
    add_column :layer_memberships, :membership_id, :integer

    LayerMembership.find_each do |layer_membership|
      if layer_membership.user_id.nil?
        puts "Removing layer_membership with id #{layer_membership.id} becuase it's user does not exists anymore."
        layer_membership.destroy
        next
      end

      if layer_membership.collection_id.nil?
        puts "Removing layer_membership with id #{layer_membership.id} becuase it's collection does not exists anymore."
        layer_membership.destroy
        next
      end

      layer_membership.membership_id = Membership.where(:collection_id => layer_membership.collection_id, :user_id => layer_membership.user_id).first.id
      layer_membership.save!
    end
    add_index :layer_memberships, :membership_id

    remove_column :layer_memberships, :user_id
    remove_column :layer_memberships, :collection_id
  end


  def down
    add_column :layer_memberships, :user_id, :integer
    add_index :layer_memberships, :user_id

    add_column :layer_memberships, :collection_id, :integer
    add_index :layer_memberships, :collection_id

    LayerMembership.find_each do |layer_membership|

      membership = Membership.find(layer_membership.membership_id)

      layer_membership.collection_id = membership.collection_id
      layer_membership.user_id = membership.user_id
      layer_membership.save!
    end

    remove_column :layer_memberships, :membership_id
  end

end
