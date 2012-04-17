class ThresholdsController < ApplicationController

  def index
    render json: thresholds
  end
end
