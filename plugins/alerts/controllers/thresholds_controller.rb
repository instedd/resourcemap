class ThresholdsController < ApplicationController
  before_filter :authenticate_user!

  before_filter :fix_conditions, only: [:create, :update]

  def index
    respond_to do |format|
      format.html do
        show_collection_breadcrumb
        add_breadcrumb "Properties", collection_path(collection)
        add_breadcrumb "Thresholds", collection_thresholds_path(collection)
      end
      format.json { render_json thresholds }
    end
  end

  def create
    params[:threshold][:sites] = params[:threshold][:sites].values.map{|site| site["id"]} if params[:threshold][:sites]
    params[:threshold][:email_notification] = {} unless params[:threshold][:email_notification] # email not selected
    params[:threshold][:phone_notification] = {} unless params[:threshold][:phone_notification] # phone not selected
    threshold = thresholds.new params[:threshold].except(:sites)
    threshold.sites = Site.get_id_and_name params[:threshold][:sites] if params[:threshold][:sites]#select only id and name
    authorize! :create, threshold
    threshold.save!
    render_json threshold
  end

  def set_order
    authorize! :set_order, threshold
    threshold.update_attribute :ord, params[:ord]

    render_json threshold
  end

  def update
    params[:threshold][:email_notification] = {} unless params[:threshold][:email_notification] # email not selected
    params[:threshold][:phone_notification] = {} unless params[:threshold][:phone_notification] # phone not selected
    params[:threshold][:sites] = params[:threshold][:sites].values.map{|site| site["id"]} if params[:threshold][:sites]
    authorize! :update, threshold
    threshold.update_attributes! params[:threshold].except(:sites)
    if params[:threshold][:sites]
      threshold.sites = Site.get_id_and_name params[:threshold][:sites]
      threshold.save
    end
    render_json threshold
  end

  def destroy
    authorize! :destroy, threshold
    threshold.destroy!
    render_json threshold
  end

  private

  def fix_conditions
    params[:threshold][:conditions] = params[:threshold][:conditions].values
  end
end
