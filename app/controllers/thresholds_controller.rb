class ThresholdsController < ApplicationController

  def index
    render json: thresholds
  end

  def create
    threshold = thresholds.new :priority => params[:threshold][:priority], :color => params[:threshold][:color], :condition => params[:threshold][:condition], :collection_id => params[:collection_id]
    threshold.save
    render json: threshold
  end

  def update
  end
  
  def destroy
    threshold = collection.thresholds.find params[:id]
    threshold.destroy

    render json: threshold
  end
end
