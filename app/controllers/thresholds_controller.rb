class ThresholdsController < ApplicationController

  def index
    render json: thresholds
  end

  def destroy
    threshold = collection.thresholds.find params[:id]
    threshold.destroy

    render json: threshold
  end
end
