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

  def delete_facility
    site.user = current_user
    site.destroy
    render json: url_for_facility(site.id)
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
    if limit == 'off'
      search.unlimited
    else
      search.limit limit
    end

    #Perform queries
    except_params = [:action, :controller, :format, :id, :sortAsc, :sortDesc, :offset, :limit, :fields, :name, :allProperties, :coordinates, :active, :createdAt, :updatedAt, :updatedSince]

    # Query by Core Properties
    search.name(params[:name]) if params[:name]
    search.id(params[:id]) if params[:id]
    search.radius(params[:coordinates][1], params[:coordinates][0], 1) if params[:coordinates]
    search.updated_at(params[:updatedAt]) if params[:updatedAt]
    search.created_at(params[:createdAt]) if params[:createdAt]

    # Query by updatedSince
    search.updated_since(params[:updatedSince]) if params[:updatedSince]

    # Query by Extended Properties
    search.where params.except(*except_params)

    #Format result
    facilities = search.api_results('fred_api')
    #Hack: All facilities are active. If param[:active]=false then no results should be returned
    facilities = [] if params[:active] == false

    fred_json_facilities = facilities.map {|facility| fred_facility_format facility}

    # Selection is made in memory for simplicity
    # In the future we could use ES method fields, but the response has different structure.
    fred_json_facilities = select_properties(fred_json_facilities, parse_fields(params[:fields])) if params[:fields]

    respond_to do |format|
      format.json { render json: fred_json_facilities}
    end

  end

  private

  def select_properties(facilities, fields_list)
    filtered_facilities = []
    facilities.each do |facility|
      filtered_facility = facility.select{|key,value| fields_list[:default].include?(key.to_s) }
      properties = facility[:properties].select{|key,value| fields_list[:custom].include?(key) }
      filtered_facility[:properties] = properties if properties.length > 0

      filtered_facilities << filtered_facility
    end
    filtered_facilities
  end

  # field_list_string has format fields=name,id,properties:numBeds
  def parse_fields(field_list_string)
    # #=> ["name,id", ",properties:", "numBeds"]
    field_list_match = field_list_string.partition(/,properties:/)
    { default: field_list_match[0].split(',') , custom: field_list_match[2].split(',')}
  end

end