class Api::SitesController < ApiController
  include Api::JsonHelper

  before_filter :authenticate_api_user!
  before_filter :authenticate_site_user!

  expose(:site)
  expose(:collection) { site.collection }

  def show
    search = new_search

    search.id(site.id)
    @result = search.api_results[0]

    respond_to do |format|
      format.rss
      format.json { render_json site_item_json(@result) }
    end
  end


  def histories
    histories = site.histories.includes(:user).select('site_histories.*, users.email')
    histories = if version = params[:version]
      histories.where(version: version)
    else
      histories.order('version ASC')
    end
    respond_to do |format|
      format.json { render_json histories.map{|h| h.attributes.merge({user: h.user.try(:email)})} }
    end
  end

  def update_property
    field = site.collection.fields.where_es_code_is params[:es_code]
    site.user = current_user
    authorize! :update_site_property, field, "Not authorized to edit site"
    updated = site.update_single_property!(params[:es_code], params[:value])
    if updated
      render_json(site, :status => 200)
    else
      error_message = site.errors[:properties][0][params[:es_code]]
      render_error_response_422(error_message)
    end
  end

  def destroy
    authorize! :delete, site, "Not authorized to delete site"
    site.user = current_user
    if site.destroy
      render_json site, status: 200
    else
      render_generic_error_response("Could not delete site")
    end
  end

  def partial_update
    site_params = JSON.parse params[:site]
    site.user = current_user
    site.validate_and_process_parameters(site_params, current_user)

    render_update_response(site)
  end

  def update
    authorize! :update, site, "Not authorized to perform a full update on site"
    site_params = JSON.parse params[:site]
    site.user = current_user
    site.properties_will_change!
    site.attributes = site.decode_properties_from_ui(site_params)

    render_update_response(site)
  end

  private

  def render_update_response(site)
    if site.valid? && site.save!
      render_json(site, status: 200)
    else
      render_error_response_422(site.errors.messages)
    end
  end
end
