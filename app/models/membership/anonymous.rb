class Membership::Anonymous
  def initialize(collection, granting_user)
    @collection = collection
    @granting_user = granting_user
  end

  def set_access(built_in_layer, access)
    raise(ArgumentError, "Undefined element #{built_in_layer} for membership.") unless built_in_layer == 'name' || built_in_layer == 'location'

    if built_in_layer == 'name'
      @collection.anonymous_name_permission = access
      changes = @collection.changes()
    else
      @collection.anonymous_location_permission = access
      changes = @collection.changes()
    end
    create_activity_when_name_or_location_changed built_in_layer, access, changes

    @collection.save!
  end

  def set_layer_access(layer_id, verb, access)
    raise(ArgumentError, "verb must be read") unless verb == "read"

    if access == "true"
      permission = "read"
    else
      permission = "none"
    end

    l = @collection.layers.find(layer_id)
    l.user = @granting_user
    l.anonymous_user_permission = permission
    l.save!
  end

  def name_permission
    @collection.anonymous_name_permission
  end

  def location_permission
    @collection.anonymous_location_permission
  end

  def as_json(options = {})
    json = {
      name: name_permission,
      location: location_permission,
    }

    json[:layers] = @collection.layers.map do |layer|
      access_level = {}
      access_level[:read] = (layer.anonymous_user_permission == "read") || (layer.anonymous_user_permission == "write")
      access_level[:write] = layer.anonymous_user_permission == "write"
      access_level[:layer_id] = layer.id
      access_level
    end

    json
  end

  def layer_access(layer_id)
    @collection.layers.find(layer_id).anonymous_user_permission
  end

  def create_activity_when_name_or_location_changed(built_in_layer, access, changes)
    if built_in_layer == 'name'
      changes = changes['anonymous_name_permission']
    else
      changes = changes['anonymous_location_permission']
    end
    data = {}
    data['built_in_layer'] = built_in_layer
    data['changes'] = changes
    Activity.create! item_type: 'anonymous_name_location_permission', action: 'changed',
    collection_id: @collection.id, data: data
  end

end
