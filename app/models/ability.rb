class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new :is_guest => true

    ### Collection ###

    # Admin abilities
    can :destroy, Collection, :memberships => { :user_id => user.id , :admin => true } 
    can :create_snapshot, Collection, :memberships => { :user_id => user.id, :admin => true } 
    can :recreate_index, Collection, :memberships => { :user_id => user.id, :admin => true } 
    can :update, Collection, :memberships => { :user_id => user.id, :admin => true }

    # User can read collection if she is a collection member or if the collection is public
    can [:read, :sites_by_term], Collection, :memberships => { :user_id => user.id }
    can [:read, :sites_by_term], Collection, :public => true

    can [:search, :index], Site, :collection => {:public => true}
    can [:search, :index], Site, :collection => {:memberships => { :user_id => user.id }}

    # Can create collection if user is not guest
    if !user.is_guest
      can [:new, :create], Collection
    end

    # Member Abilities
    can :csv_template, Collection, :memberships => { :user_id => user.id }
    can :upload_csv, Collection, :memberships => { :user_id => user.id }
    can :unload_current_snapshot, Collection, :memberships => { :user_id => user.id }
    can :load_snapshot, Collection, :memberships => { :user_id => user.id }
    can :max_value_of_property, Collection, :memberships => { :user_id => user.id }
    can :search, Collection, :memberships => { :user_id => user.id }
    can :decode_hierarchy_csv, Collection, :memberships => { :user_id => user.id }
    can :register_gateways, Collection, :memberships => { :user_id => user.id }
    can :message_quota, Collection, :memberships => { :user_id => user.id }
    can :members, Collection, :memberships => { :user_id => user.id }
    can :reminders, Collection, :memberships => { :user_id => user.id }
    can :settings, Collection, :memberships => { :user_id => user.id }
    can :quotas, Collection, :memberships => { :user_id => user.id }

  end
end
