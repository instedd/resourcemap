class ThresholdsController < ApplicationController

  def index
    render json: collection.thresholds 
  end
end
