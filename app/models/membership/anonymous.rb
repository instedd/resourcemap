class Anonymous
  def initialize(collection, granting_user)
    @collection = collection
    @granting_user = granting_user
  end

  def set_layer_access(layer_id, access_level)
    l = @collection.layers.find(layer_id)
    l.user = @granting_user
    l.anonymous_user_permission = access_level
    l.save!
  end

  def name_permission
    name_location_permission
  end

  def location_permission
    name_location_permission
  end

  def as_json(options = {})
    json = { name: name_permission, location: location_permission }
    @collection.layers.each do |layer|
      json[layer[:id].to_s] = layer[:anonymous_user_permission]
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
