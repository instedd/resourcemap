class ThresholdsController < ApplicationController
  before_filter :authenticate_user!

  before_filter :fix_conditions, only: [:create, :update]

  def index
    respond_to do |format|
      format.html do
        show_collection_breadcrumb
        add_breadcrumb "Thresholds", collection_thresholds_path(collection)
      end
      format.json { render json: thresholds }
    end
  end

  def create
    threshold = thresholds.new params[:threshold].except(:sites) 
    threshold.sites = Site.select("id, name").find(params[:threshold][:sites]) if params[:threshold][:sites]  #select only id and name
    threshold.save!
    render json: threshold
  end

  def set_order
    threshold.update_attribute :ord, params[:ord]

    render json: threshold
  end

  def update
    threshold.update_attributes! params[:threshold].except(:sites)
    if params[:threshold][:sites]
      threshold.sites = Site.select("id, name").find(params[:threshold][:sites])  #select only id and name
      threshold.save 
    end 
    render json: threshold
  end

  def destroy
    threshold.destroy

    render json: threshold
  end

  private

  def fix_conditions
    params[:threshold][:conditions] = params[:threshold][:conditions].values
  end
end
