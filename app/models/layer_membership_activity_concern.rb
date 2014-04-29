module LayerMembershipActivityConcern
  extend ActiveSupport::Concern

  included do
    attr_accessor :activity_user
    after_create :create_activity_for_layer
    before_destroy :create_activity_if_destroy_permission
  end

  def create_activity_for_layer
    if activity_user
      Activity.create! item_type: 'layer_membership', action: 'created', collection_id: membership.collection_id, layer_id: layer.id, user_id: activity_user.id, 'data' => {'read' => read, 'write' => write, 'name' => layer.name, 'user' => membership.user.email}
    end
  end

  def create_activity_if_destroy_permission
    if activity_user
      data = changes
      data['name'] = layer.name
      data['user'] = membership.user.email
      Activity.create! item_type: 'layer_membership', action: 'deleted', collection_id: layer.collection_id, layer_id: layer.id, user_id: activity_user.id, 'data' => data
    end
  end

end
