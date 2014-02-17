class AnonymousMembership
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
end
