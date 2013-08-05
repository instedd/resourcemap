class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new :is_guest => true

    ### Collection ###

    # Admin abilities
    can [:destroy, :create_snapshot, :recreate_index, :update, :members, :import_layers_from], Collection, :memberships => { :user_id => user.id , :admin => true }
    can :manage, Snapshot, :collection => {:memberships => { :user_id => user.id , :admin => true } }

    # User can read collection if she is a collection member or if the collection is public
    can [:read, :sites_by_term, :search, :sites_info], Collection, :memberships => { :user_id => user.id }
    can [:read, :sites_by_term, :search, :sites_info], Collection, :public => true

    can [:search, :index], Site, :collection => {:public => true}
    can [:search, :index], Site, :collection => {:memberships => { :user_id => user.id }}

    if !user.is_guest
      can [:new, :create], Collection
    end

    # Member Abilities
    can [:csv_template, :upload_csv, :unload_current_snapshot, :load_snapshot, :register_gateways, :message_quota, :reminders, :settings, :quotas], Collection, :memberships => { :user_id => user.id }

    # In progress
    can :max_value_of_property, Collection, :memberships => { :user_id => user.id }
    can :decode_hierarchy_csv, Collection, :memberships => { :user_id => user.id }



    ### Layer ###

    # A user may read a layer if she's the collection administrator...
    can :read, Layer, :collection => { :memberships => { :user_id => user.id, :admin => true } }
    # ...or if she has been given explicit read access to it.
    can :read, Layer, :collection => { :memberships => { :user_id => user.id} }, :id => user.readable_layer_ids
    # ...or if the user is guest
    if user.is_guest
      can :read, Layer, :collection => {:public => true}
    end

    # A user can write a layer only if she is the collection admin
    can :update, Layer, :collection => { :memberships => { :user_id => user.id, :admin => true } }
    can :create, Layer, :collection => { :memberships => { :user_id => user.id, :admin => true } }
    can :destroy, Layer, :collection => { :memberships => { :user_id => user.id, :admin => true } }

    ### Layer History ###

    # Same read permissions of Layer
    can :read, LayerHistory, :collection => { :memberships => { :user_id => user.id, :admin => true } }
    can :read, LayerHistory, :collection => { :memberships => { :user_id => user.id} }, :id => user.readable_layer_ids
    if user.is_guest
      can :read, LayerHistory, :collection => {:public => true}
    end

    ### Site properties ###
    can :read_site_property, Field do |field, site|
      can? :read, field.layer
    end

    can :update_site_property, Field do |field, site|
      admin = user.memberships.where(:collection_id => field.collection_id).first.try(:admin?)
      lm = LayerMembership.where(user_id: user.id, layer_id: field.layer_id).first
      admin || (lm && lm.write)
    end


  end
end
