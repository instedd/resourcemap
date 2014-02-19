class Anonymous
  def initialize(collection, granting_user)
    @collection = collection
    @granting_user = granting_user
  end

  def set_layer_access(options = {})
    l = @collection.layers.find(options[:layer_id])
    l.user = @granting_user
    l.anonymous_user_permission = options[:verb]
    l.save!
  end

  def name_permission
    name_location_permission
  end

  def location_permission
    name_location_permission
  end

  def to_json
    json = { name: name_permission, location: location_permission }
    @collection.layers.each do |layer|
      json[layer[:id].to_s] = layer[:anonymous_user_permission]
    end
    json
  end

  private

  def name_location_permission
    permission = @collection.public ? "read" : "none"
    permission
  end

end
