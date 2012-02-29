class LayersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :fix_field_options, :only => [:create, :update]

  def index
    respond_to do |format|
      format.html do
        @show_breadcrumb = true
        add_breadcrumb "Collections", collections_path
        add_breadcrumb collection.name, collection_path(collection)
        add_breadcrumb "Layers", collection_layers_path(collection)
      end
      format.json { render :json => layers.as_json(:include => :fields) }
    end
  end

  def create
    layer = layers.new params[:layer]
    layer.save
    render :json => layer
  end

  def update
    layer.fields.destroy_all
    layer.update_attributes params[:layer]
    render :json => layer
  end

  def destroy
    layer.destroy
    head :ok
  end

  private

  def fix_field_options
    if params[:layer] && params[:layer][:fields_attributes]
      params[:layer][:fields_attributes].each do |field_idx, field|
        field[:config][:options] = field[:config][:options].values if field[:config] && field[:config][:options]
      end
    end
  end
end
