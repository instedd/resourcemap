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
    threshold = thresholds.new params[:threshold]
    threshold.save!
    render json: threshold
  end

  def set_order
    threshold.update_attribute :ord, params[:ord]

    render json: threshold
  end

  def update
    threshold.update_attributes params[:threshold]
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
