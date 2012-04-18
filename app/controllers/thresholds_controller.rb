class ThresholdsController < ApplicationController

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

  def destroy
    threshold = collection.thresholds.find params[:id]
    threshold.destroy

    render json: threshold
  end
end
