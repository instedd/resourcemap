module LayerMembershipActivityConcern
  extend ActiveSupport::Concern

  included do
    after_create :create_activity_for_layer
    before_destroy :create_activity_if_destroy_permission
  end

  def create_activity_for_layer
    Activity.create! item_type: 'layer_membership', action: 'created', collection_id: membership.collection_id, layer_id: layer.id, user_id: membership.user_id, 'data' => {'read' => read, 'write' => write, 'name' => layer.name}
  end

  def create_activity_if_destroy_permission
    data = changes
    data['name'] = layer.name
    Activity.create! item_type: 'layer_membership', action: 'deleted', collection_id: layer.collection_id, layer_id: layer.id, user_id: membership.user_id, 'data' => data
  end


end
