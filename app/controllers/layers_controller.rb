class LayersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :fix_field_options, only: [:create, :update]

  def index
    respond_to do |format|
      format.html do
        @show_breadcrumb = true
        add_breadcrumb "Collections", collections_path
        add_breadcrumb collection.name, collection_path(collection)
        add_breadcrumb "Layers", collection_layers_path(collection)
      end
      format.json { render json: layers.as_json(include: :fields) }
    end
  end

  def create
    layer = layers.new params[:layer]
    layer.user = current_user
    layer.save!
    render json: layer.as_json(include: :fields)
  end

  def update
    fix_layer_fields_for_update
    layer.update_attributes! params[:layer]
    layer.reload
    render json: layer.as_json(include: :fields)
  end

  def set_order
    layer.update_attributes! ord: params[:ord]
    render json: layer
  end

  def destroy
    layer.user = current_user
    layer.destroy
    head :ok
  end

  private

  # The options come as a hash insted of a list, so we convert the hash to a list
  def fix_field_options
    if params[:layer] && params[:layer][:fields_attributes]
      params[:layer][:fields_attributes].each do |field_idx, field|
        field[:config][:options] = field[:config][:options].values if field[:config] && field[:config][:options]
      end
    end
  end

  # Instead of sending the _destroy flag to destroy fields (complicates things on the client side code)
  # we check which are the current fields ids, which are the new ones and we delete those fields
  # whose ids don't show up in the new ones.
  #
  # That way we preserve existing fields and we can know if their codes change, to trigger a reindex
  def fix_layer_fields_for_update
    fields = layer.fields
    fields_ids = fields.map &:id
    new_ids = params[:layer][:fields_attributes].values.map { |x| x[:id].try(:to_i) }.compact
    removed_fields_ids = fields_ids - new_ids
    removed_fields_ids.each do |id|
      fields.find { |f| f.id == id }.destroy
    end
  end
end
