class FredApi::FredApiController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_site_user!, :only => [:show_facility]

  include FredApi::JsonHelper

  expose(:site)

  def show_facility
    search = site.collection.new_search current_user_id: current_user.id
    search.id(site.id)
    results = search.api_results('fred_api')

    # ID is unique. We should only get one result here.
    facility = results[0]

    respond_to do |format|
      format.json { render json: fred_facility_format(facility) }
    end
  end

  def facilities
    # We assume that FRED API users will only have one collection.
    # In case they have more than one collection, we will query the first created.
    collection = current_user.collections.reorder('created_at asc').first

    search = collection.new_search current_user_id: current_user.id

    search.use_codes_instead_of_es_codes

    # Sort can only be performed by a single field
    search.sort params[:sortAsc], true if params[:sortAsc]
    search.sort params[:sortDesc], false if params[:sortDesc]

    offset = params[:offset] ?  params[:offset] : 0
    search.offset offset
    limit = params[:limit] ? params[:limit] : 25
    search.limit limit

    facilities = search.api_results('fred_api')

    respond_to do |format|
      format.json { render json: facilities.map {|facility| fred_facility_format facility} }
    end

  end

end