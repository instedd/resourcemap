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
    site.properties_will_change!
    site.assign_default_values_for_update
    site.properties[params[:es_code]] = field.decode_from_ui(params[:value])
    if site.valid? && site.save
      render_json(site, :status => 200)
    else
      error_message = site.errors[:properties][0][params[:es_code]]
      render_error_response_422(error_message)
    end
  end
end
