class Api::LayersController < ApiController

  # We removed the public attribute from layers, but we'll accept requests sending it
  # so we don't break compatibility with already running clients.
  before_filter :ignore_public_attribute
  expose(:layer)

  # authorize_resource :layer, only: [:destroy, :update], :decent_exposure => true

  def index
    render_json collection.layers_to_json(current_user_snapshot.at_present?, current_user)
  end

  def create
    layer = current_user.create_layer_for(collection, params[:layer])
    render_json layer.as_json(include: :fields)
  end

  def update
    # FIX: For some reason using the exposed layer here results in duplicated fields being created
    layer = collection.layers.find params[:id]
    params[:layer][:fields_attributes] = layer.fix_layer_fields_for_update(params[:layer][:fields_attributes])

    layer.user = current_user
    layer.update_attributes! params[:layer]
    layer.reload
    render_json layer.as_json(include: :fields)
  end

  def destroy
    layer.user = current_user
    if layer.destroy
      head :ok
    else
      render_generic_error_response("Could not delete layer")
    end
  end
end
