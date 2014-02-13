class AnonymousMembership

  def set_layer_access(options = {})
    l = layers.where(:id => options[:layer_id])
    l.anonymous_permission = options[:verb]
    l.save!
  end
end
