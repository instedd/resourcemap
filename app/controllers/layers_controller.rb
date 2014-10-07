class LayersController < ApplicationController

  before_filter :authenticate_api_user!

  # We removed the public attribute from layers, but we'll accept requests sending it
  # so we don't break compatibility with already running clients.
  before_filter :ignore_public_attribute

  before_filter :fix_field_config, only: [:create, :update]


  # authorize_resource :layer, :decent_exposure => true, :except => :create

  expose(:layers) {
    authorize! :read, collection

    if !current_user_snapshot.at_present? && collection then
      collection.layer_histories.accessible_by(current_ability).uniq.at_date(current_user_snapshot.snapshot.date)
    else
      collection.layers.accessible_by(current_ability).uniq
    end
  }

  expose(:layer)

  def index
    layers # signal that layers will be used on this page (loaded by ajax later)
    respond_to do |format|
      format.html do
        show_collection_breadcrumb
        add_breadcrumb "Properties", collection_path(collection)
        add_breadcrumb "Layers", collection_layers_path(collection)
      end
      format.json { render_json collection.layers_to_json(current_user_snapshot.at_present?, current_user) }
    end
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

  def set_order
    # cancan layer is 'readonly' :S
    # https://github.com/ryanb/cancan/issues/357
    layer = collection.layers.find(params[:id],  :readonly => false)

    layer.user = current_user
    layer.update_attributes! ord: params[:ord]
    render_json layer
  end

  def destroy
    layer.user = current_user
    layer.destroy
    head :ok
  end

  def decode_hierarchy_csv
    @hierarchy = collection.decode_hierarchy_csv_file(params[:file].path)
    @hierarchy_errors = collection.generate_error_description_list(@hierarchy)
    render layout: false
  end

  private

  # The options come as a hash insted of a list, so we convert the hash to a list
  # Also fix hierarchy in the same way.
  def fix_field_config
    if params[:layer] && params[:layer][:fields_attributes]
      params[:layer][:fields_attributes].each do |field_idx, field|
        if field[:config]
          if field[:config][:options]
            field[:config][:options] = field[:config][:options].values
            field[:config][:options].each { |option| option['id'] = option['id'].to_i }
          end
          field[:config][:next_id] = field[:config][:next_id].to_i if field[:config][:next_id]
          if field[:config][:hierarchy]
            field[:config][:hierarchy] = field[:config][:hierarchy].values
            sanitize_items field[:config][:hierarchy]
          end
        end
      end
    end
  end

  def sanitize_items(items)
    items.each do |item|
      if item[:sub]
        item[:sub] = item[:sub].values
        sanitize_items item[:sub]
      end
    end
  end
end
