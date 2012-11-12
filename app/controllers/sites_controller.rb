class SitesController < ApplicationController
  before_filter :authenticate_user!

  expose(:sites) {if current_snapshot && collection then collection.site_histories.at_date(current_snapshot.date) else collection.sites end}
  expose(:site) { Site.find(params[:site_id] || params[:id]) }

  def index
    if current_snapshot
      search = collection.new_search snapshot_id: current_snapshot.id, current_user_id: current_user.id
    else
      search = collection.new_search current_user_id: current_user.id
    end
    search.name_start_with params[:name] if params[:name].present?
    search.offset params[:offset]
    search.limit params[:limit]
    render json: search.ui_results.map { |x| x['_source'] }
  end

  def show
    if current_snapshot
      search = collection.new_search snapshot_id: current_snapshot.id, current_user_id: current_user.id
    else
      search = collection.new_search current_user_id: current_user.id
    end
    search.id params[:id]
    render json: search.ui_results.first['_source']
  end

  def create
    site = collection.sites.create(JSON.parse(params[:site]).merge(user: current_user))
    render json: site
  end

  def update
    site.user = current_user
    site.properties_will_change!
    site.update_attributes! JSON.parse(params[:site])
    render json: site
  end

  def update_property
    field = site.collection.fields.where_es_code_is(params[:es_code]).first

    return head :forbidden unless current_user.can_write_field? field, site.collection, params[:es_code]

    site.user = current_user
    site.properties_will_change!

    site.properties[params[:es_code]] = field.apply_format_update_validation(params[:value], false, collection)
    site.save!
    render json: site
  end

  def search
    zoom = params[:z].to_i

    search = MapSearch.new params[:collection_ids], user: current_user

    search.zoom = zoom
    search.bounds = params if zoom >= 2
    search.exclude_id params[:exclude_id].to_i if params[:exclude_id].present?
    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search] if params[:search].present?
    search.location_missing if params[:location_missing].present?
    if params[:selected_hierarchies].present?
      search.selected_hierarchy params[:hierarchy_code], params[:selected_hierarchies]
    end
    search.where params.except(:action, :controller, :format, :n, :s, :e, :w, :z, :collection_ids, :exclude_id, :updated_since, :search, :location_missing, :selected_hierarchies, :hierarchy_code)

    search.apply_queries

    render json: search.results
  end

  def destroy
    site.user = current_user
    site.destroy
    render json: site
  end
end
