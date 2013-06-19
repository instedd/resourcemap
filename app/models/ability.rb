class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new :is_guest => true

    ### Collection ###

    # Admin abilities
    can [:destroy, :create_snapshot, :recreate_index, :update, :members], Collection, :memberships => { :user_id => user.id , :admin => true }
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
  end
end
