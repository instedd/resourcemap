class ThresholdsController < ApplicationController
  before_filter :authenticate_user!

  def index
    respond_to do |format|
      format.html do
        @show_breadcrumb = true
        add_breadcrumb "Collections", collections_path
        add_breadcrumb collection.name, collection_path(collection)
        add_breadcrumb "Thresholds", collection_thresholds_path(collection)
      end
      format.json { render json: thresholds }
    end
  end

  def create
    threshold = thresholds.new :priority => params[:threshold][:priority], :color => params[:threshold][:color], :conditions => params[:threshold][:conditions].values, :collection_id => params[:collection_id]
    threshold.save
    render json: threshold
  end

  def set_priority
    threshold.update_attribute :priority, params[:priority]

    render json: threshold
  end
  
  def update
    params[:threshold][:conditions] = params[:threshold][:conditions].values
    threshold.update_attributes params[:threshold]
    render json: threshold
  end
  
  def destroy
    threshold.destroy

    render json: threshold
  end
end
