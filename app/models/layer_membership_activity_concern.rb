module LayerMembershipActivityConcern
  extend ActiveSupport::Concern

  included do
    after_create :create_activity_for_layer
  end

  def create_activity_for_layer
    Activity.create! item_type: 'layer_membership', action: 'created', collection_id: layer.collection.id, layer_id: layer.id, user_id: membership.user_id, 'data' => {'read' => read, 'write' => write, 'name' => layer.name}
  end

end
