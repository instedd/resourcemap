class Ability

  include CanCan::Ability

  def initialize(user, format = nil)

    ### Collection ###

    # Admin abilities
    alias_action :destroy, :create_snapshot, :recreate_index, :update,
                  :members, :import_layers_from, :upload_logo, :edit_logo, :export,
                  :to => :admin

    can :admin, Collection, :memberships => { :user_id => user.id , :admin => true }
    can :manage, Snapshot, :collection => {:memberships => { :user_id => user.id , :admin => true } }

    # User can read collection if she is a collection member or if the collection is public
    can [:read, :sites_by_term, :search, :sites_info, :current_user_membership], Collection, :memberships => { :user_id => user.id }
    can [:sites_by_term, :search, :sites_info, :current_user_membership, :export], Collection, :anonymous_name_permission => "read"
    # Permission to read collection was allowing guest to see settings page
    can :read, Collection, :anonymous_name_permission => "read" unless format && format.html?

    can [:search, :index], Site, :collection => {:anonymous_name_permission => "read"}
    can [:search, :index], Site, :collection => {:memberships => { :user_id => user.id }}
    can :delete, Site, :collection => {:memberships => { :user_id => user.id , :admin => true } }

    if !user.is_guest
      can [:new, :create], Collection
    end

    # Member Abilities
    can [:csv_template, :upload_csv, :unload_current_snapshot, :load_snapshot, :register_gateways, :message_quota, :reminders, :settings, :quotas, :export], Collection, :memberships => { :user_id => user.id }

    # In progress
    can :max_value_of_property, Collection, :memberships => { :user_id => user.id }


    ### Layer ###
    can :read, Layer, :anonymous_user_permission => "read"

    if !user.is_guest
      # A user may read a layer if she's the collection administrator...
      can :read, Layer, :collection => { :memberships => { :user_id => user.id, :admin => true } }
      # ...or if she has been given explicit read access to it.
      can :read, Layer, :collection => { :memberships => { :user_id => user.id} }, :id => user.readable_layer_ids
    end

    # A user can write a layer only if she is the collection admin
    can :update, Layer, :collection => { :memberships => { :user_id => user.id, :admin => true } }
    can :create, Layer, :collection => { :memberships => { :user_id => user.id, :admin => true } }
    can :destroy, Layer, :collection => { :memberships => { :user_id => user.id, :admin => true } }
    can :set_order, Layer, :collection => { :memberships => { :user_id => user.id, :admin => true } }
    can :order, Layer, :collection => { :memberships => { :user_id => user.id, :admin => true } }
    can :hierarchy_editor, Layer, :collection => { :memberships => { :user_id => user.id, :admin => true } }
    can :decode_hierarchy_csv, Layer, :collection => { :memberships => { :user_id => user.id, :admin => true } }

    ### Layer History ###

    # Same read permissions of Layer
    if !user.is_guest
      can :read, LayerHistory, :collection => { :memberships => { :user_id => user.id, :admin => true } }
      can :read, LayerHistory, :collection => { :memberships => { :user_id => user.id} }, :layer_id => user.readable_layer_ids
    else
      can :read, LayerHistory, :layer_id => user.readable_layer_ids
    end

    ### Site properties ###
    can :read_site_property, Field do |field, site|
      can? :read, field.layer
    end

    can :update_site_property, Field do |field, site|
      if user.is_guest
        false
      else
        membership = user_memberships(user).find{|um| um.collection_id == field.collection_id}

        if membership
          admin = membership.try(:admin?)
          lm = membership.layer_memberships.find{|layer_membership| layer_membership.layer_id == field.layer_id}
          admin || (lm && lm.write)
        else
          false
        end
      end
    end

    # Full update, only admins have rights to do this
    can :update, Site, :collection => { :memberships => { :user_id => user.id, :admin => true } }

    can :update_name, Membership do |user_membership|
      user_membership.can_update?("name")
    end

    can :update_location, Membership do |user_membership|
      user_membership.can_update?("location")
    end

    ### Reminders ###

    can [:create, :update, :read, :destroy, :set_status], Reminder, :collection => { :memberships => { :user_id => user.id } }

    ### Alerts ###

    can [:create, :update, :read, :destroy, :set_order], Threshold, :collection => { :memberships => { :user_id => user.id } }

  end

  def user_memberships(user)
    @user_memberships ||= user.memberships.includes(:layer_memberships)
  end
end
