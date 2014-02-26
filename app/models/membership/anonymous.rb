class Membership::Anonymous
  def initialize(collection, granting_user)
    @collection = collection
    @granting_user = granting_user
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
    name_location_permission
  end

  def location_permission
    name_location_permission
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

  private

  def name_location_permission
    permission = @collection.public ? "read" : "none"
    permission
  end

end
