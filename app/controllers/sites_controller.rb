class SitesController < ApplicationController
  before_filter :authenticate_api_user!, :except => [:index, :search], :unless => Proc.new { collection && collection.anonymous_name_permission == 'read' }
  before_filter :authenticate_collection_admin!, :only => :update

  authorize_resource :only => [:index, :search], :decent_exposure => true

  expose(:sites) {if !current_user_snapshot.at_present? && collection then collection.site_histories.at_date(current_user_snapshot.snapshot.date) else collection.sites end}
  expose(:site) { Site.find(params[:site_id] || params[:id]) }

  def index
    search = new_search

    search.name_start_with params[:sitename] if params[:sitename].present?
    search.offset params[:offset]
    search.limit params[:limit]

    results = search.ui_results
    render_json({ sites: results.map { |x| x['_source'] }, total_count: results.total_count })
  end

  def show
    search = new_search

    search.id params[:id]
    # If site does not exists, return empty object
    result = search.ui_results.first['_source'] rescue {}
    render_json result
  end

  def create
    site_params = JSON.parse params[:site]

    site = collection.sites.new(user: current_user)

    site.validate_and_process_parameters(site_params, current_user)

    site.assign_default_values_for_create

    if site.valid?
      site.save!
      current_user.increase_site_count_and_status
      render_json site, :layout => false
    else
      render_json site.errors.messages, status: :unprocessable_entity, :layout => false
    end
  end

  # This action updates the entire entity.
  # It performs a full update, erasing the values for the fields that are not present in the request
  # It is only accessible by admins: there are no permission validations in the code
  def update
    site_params = JSON.parse params[:site]
    site.user = current_user
    site.properties_will_change!
    site.attributes = site.decode_properties_from_ui(site_params)

    if site.valid?
      site.save!
      render_json(site, :layout => false)
    else
      render_json(site.errors.messages, status: :unprocessable_entity, :layout => false)
    end
  end

  # This action modifies only the fields that are present in the request.
  def partial_update
    site_params = JSON.parse params[:site]
    site.user = current_user

    site.validate_and_process_parameters(site_params, current_user)

    if site.valid?
      site.save!
      render_json(site, :layout => false)
    else
      render_json(site.errors.messages, status: :unprocessable_entity, :layout => false)
    end
  end

  def update_property
    field = site.collection.fields.where_es_code_is params[:es_code]

    #Pending: Check custom site permission
    return forbidden_response unless can?(:update_site_property, field)

    site.user = current_user
    updated = site.update_single_property!(params[:es_code], params[:value])
    if updated
      render_json(site, :status => 200, :layout => false)
    else
      error_message = site.errors[:properties][0][params[:es_code]]
      render_json({:error_message => error_message}, status: :unprocessable_entity, :layout => false)
    end
  end

  def search
    zoom = params[:z].to_i

    if params[:collection_ids].is_a? String
      collection_ids_array = params[:collection_ids].split ","
    elsif params[:collection_ids].is_a? Array
      collection_ids_array = params[:collection_ids]
    end

    search = MapSearch.new collection_ids_array, user: current_user

    search.zoom = zoom
    search.bounds = params if zoom >= 2
    search.exclude_id params[:exclude_id].to_i if params[:exclude_id].present?
    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search] if params[:search].present?
    search.location_missing if params[:location_missing].present?
    search.name_search params[:sitename] if params[:sitename].present?
    if params[:selected_hierarchy_id].present?
      search.selected_hierarchy params[:hierarchy_code], Field.find(params[:hierarchy_code]).descendants_of_in_hierarchy(params[:selected_hierarchy_id])
    end
    search.where params.except(:action, :controller, :format, :n, :s, :e, :w, :z, :collection_ids, :exclude_id, :updated_since, :search, :location_missing, :hierarchy_code, :selected_hierarchy_id, :locale, :sitename)
    render_json search.results
  end

  def destroy
    # TODO: authorice resource for all the controller's actions
    authorize! :delete, site
    site.user = current_user
    site.destroy
    render_json site
  end

end
