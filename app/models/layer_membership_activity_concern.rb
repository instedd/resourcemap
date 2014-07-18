module LayerMembershipActivityConcern
  extend ActiveSupport::Concern

  included do
    attr_accessor :activity_user
    after_create :create_activity_for_layer
    before_destroy :create_activity_if_destroy_permission
    before_update :create_activity_if_permission_changed
  end

  def create_activity_for_layer
    if changes['write']
      new_permission = 'update'
    else
      new_permission = 'read'
    end
    if activity_user
      Activity.create! item_type: 'layer_membership', action: 'changed', collection_id: membership.collection_id, layer_id: layer.id, user_id: activity_user.id, 'data' => {'previous_permission' => 'none', 'new_permission' => new_permission, 'name' => layer.name, 'user' => membership.user.email}
    end
  end

  def create_activity_if_destroy_permission
    if changes['write']
      previous_permission = 'update'
    else
      previous_permission = 'read'
    end
    if activity_user
      Activity.create! item_type: 'layer_membership', action: 'changed', collection_id: layer.collection_id, layer_id: layer.id, user_id: activity_user.id, 'data' => {'previous_permission' => previous_permission, 'new_permission' => 'none', 'name' => layer.name, 'user' => membership.user.email}
    end
  end

  def create_activity_if_permission_changed
    if changes['write'][0]
      previous_permission = 'update'
      new_permission = 'read'
    else
      previous_permission = 'read'
      new_permission = 'update'
    end
    if activity_user
      Activity.create! item_type: 'layer_membership', action: 'changed', collection_id: layer.collection_id, user_id: activity_user.id, layer_id: layer.id, user_id: activity_user.id, 'data' => {'previous_permission' => previous_permission, 'new_permission' => new_permission, 'name' => layer.name, 'user' =>
        membership.user.email}
    end
  end

end
