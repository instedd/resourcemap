class Api::LayersController < ApiController

  # We removed the public attribute from layers, but we'll accept requests sending it
  # so we don't break compatibility with already running clients.
  before_filter :ignore_public_attribute

  def index
    render_json collection.layers_to_json(current_user_snapshot.at_present?, current_user)
  end

  def create
    layer = current_user.create_layer_for(collection, params[:layer])
    render_json layer.as_json(include: :fields)
  end
end
