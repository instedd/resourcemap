class FredApiController < ApplicationController
  skip_before_action :set_gettext_locale
  skip_before_action :redirect_to_localized_url
  skip_before_action :verify_authenticity_token

  before_action :authenticate_collection_admin!
  before_action :authenticate_api_user!

  before_action :verify_site_belongs_to_collection!, :only => [:show_facility, :update_facility]
  before_action :authenticate_site_user!, :only => [:show_facility, :delete_facility, :update_facility]

  rescue_from Exception, :with => :default_rescue
  rescue_from RuntimeError, :with => :rescue_runtime_error
  rescue_from ActionController::RoutingError, :with => :rescue_record_not_found
  rescue_from ActiveRecord::RecordNotFound, :with => :rescue_record_not_found
  rescue_from ActiveRecord::RecordInvalid, :with => :rescue_record_invalid

  expose(:site)
  expose(:collection) { Collection.find params[:collection_id] }

  def verify_site_belongs_to_collection!
    if !collection.sites.include? site
      render_json({ message: "Facility #{site.id} do not belong to collection #{collection.id}"}, status: 409)
    end
  end

  def forbidden_response
    render_json({ message: "Permissions were insufficient to perform the request", code: 403}, status: 403)
  end

  def unauthorized_response
    render_json({ message: "This action requires authorization", code: 401}, status: 401)
  end

  def show_facility
    render_json find_facility_and_apply_fred_format(site.id)
  end

  def delete_facility
    if !collection.sites.include? site
      render_json(code: "404 Not Found", message: "Resource not found")
    else
      id = site.id
      site.user = current_user
      site.destroy
      render_json(code: 200, id: site.id.to_s, message: "Resource deleted")
    end
  end

  def update_facility
    raw_post = request.raw_post.empty? ? "{}" : request.raw_post
    facility_params = JSON.parse raw_post

    if ["id","uuid","url","createdAt","updatedAt"].any?{|invalid_param| facility_params.include? invalid_param}
      render_json({ message: "Invalid Paramaters: The id, uuid, url, createdAt and updatedAt core properties cannot be changed by the client."}, status: 400)
      return
    end
    facility_params = validate_site_params(facility_params)
    site.user = current_user
    site.validate_and_process_parameters facility_params, current_user
    site.save!

    render_json(find_facility_and_apply_fred_format(site.id), status: :ok, :location => url_for_facility(site.id))
  end

  def create_facility
    raw_post = request.raw_post.empty? ? "{}" : request.raw_post
    facility_params = JSON.parse raw_post
    if ["id","url","createdAt","updatedAt"].any?{|invalid_param| facility_params.include? invalid_param}
      render_json({ message: "Invalid Paramaters: The id, url, createdAt and updatedAt core properties cannot be changed by the client."}, status: 400)
      return
    end
    facility_params = validate_site_params(facility_params)
    facility = collection.sites.new
    facility.update_attributes! facility_params.merge(user: current_user)
    facility.assign_default_values_for_create
    facility.save!
    render_json(find_facility_and_apply_fred_format(facility.id), status: :created, :location => url_for_facility(facility.id))
  end

  def facilities
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
    except_params = [:action, :controller, :format, :id, :collection_id, :sortAsc, :sortDesc, :offset, :limit, :fields, :name, :allProperties, :coordinates, :active, :createdAt, :updatedAt, :updatedSince, "identifiers.id", "identifiers.agency", "identifiers.context", :uuid, :locale]

    # Query by Core Properties
    search.name(params[:name]) if params[:name]
    search.id(params[:id]) if params[:id]
    search.uuid(params[:uuid]) if params[:uuid]

    search.radius(params[:coordinates][1], params[:coordinates][0], 1) if params[:coordinates]
    search.updated_at(params[:updatedAt]) if params[:updatedAt]
    search.created_at(params[:createdAt]) if params[:createdAt]

    # Query by updatedSince
    search.updated_since(params[:updatedSince]) if params[:updatedSince]

    # Query by Extended Properties
    params_query = params.except(*except_params).to_h
    property_params = remove_prefix_form_properties_params(params_query)
    search.where property_params

    # Query by identifiers
    if params["identifiers.context"] && params["identifiers.id"] && params["identifiers.agency"]
      search.identifier_context_agency_and_id(params["identifiers.context"], params["identifiers.agency"], params["identifiers.id"])
    elsif params["identifiers.agency"] && params["identifiers.id"]
      search.identifier_agency_and_id(params["identifiers.agency"], params["identifiers.id"])
    elsif params["identifiers.context"] && params["identifiers.id"]
      search.identifier_context_and_id(params["identifiers.context"], params["identifiers.id"])
    elsif params["identifiers.id"]
      search.identifier_id(params["identifiers.id"])
    end

    #Format result
    facilities = search.fred_api_results
    #Hack: All facilities are active. If param[:active]=false then no results should be returned
    facilities = [] if params[:active].to_s == false.to_s

    @fred_json_facilities = facilities.map {|facility| fred_facility_format_from_ES facility}

    # Selection is made in memory for simplicity
    # In the future we could use ES method fields, but the response has different structure.
    @fred_json_facilities = select_properties(@fred_json_facilities, parse_fields(params[:fields])) if params[:fields]

    respond_to do |format|
      format.json { render_json({facilities: @fred_json_facilities}) }
      format.xml { render template: 'fred_api/facilities.xml.builder', layout: false }
    end
  end

  private

  # Remove 'properties.' prefix form params
  def remove_prefix_form_properties_params(params_query)
    res = {}
    params_query.each_pair do |key, val|
      res[key.gsub(/properties./, "")] = val
    end
    res
  end

  def find_facility_and_apply_fred_format(id)
    search = collection.new_search current_user_id: current_user.id
    search.id(id)
    results = search.fred_api_results

    # ID is unique. We should only get one result here.
    facility = results[0]

    fred_facility_format_from_ES(facility)
  end

  def validate_site_params(facility_param)

    if facility_param.include? "active"
      facility_param.delete("active")
    end

    fields = collection.fields.index_by(&:code)
    properties = facility_param["properties"] || {}

    properties_with_identifiers = properties.merge(convert_to_properties(facility_param["identifiers"]))

    properties_by_es_code = {}
    properties_with_identifiers.each_pair do |code, value|
      field = fields[code]
      if field.nil?
        raise "Invalid Parameters: Cannot find Field with code equal to '#{code}' in Collection's Layers."
      end
      properties_by_es_code["#{field.es_code}"] = field.decode_fred value
    end

    properties_with_identifiers = properties_by_es_code

    lat = facility_param["coordinates"][1] if facility_param["coordinates"]
    lng = facility_param["coordinates"][0] if facility_param["coordinates"]

    facility_param.delete "coordinates"
    facility_param.delete "identifiers"

    validated_site = facility_param
    validated_site["properties"] = properties_with_identifiers
    validated_site["lat"] = lat
    validated_site["lng"] = lng

    validated_site
  end

  def convert_to_properties(params_idetifiers)
    identifiers = params_idetifiers || []
    as_properties = {}
    identifiers_fields = collection.fields.find_all{|f| f.identifier?}
    identifiers.each do |identifier|
      field = identifiers_fields.find{|f| f.context == identifier["context"] && f.agency == identifier["agency"] }
      raise "Invalid Parameters: Cannot find Identifier Field with context equal to '#{identifier["context"]}' and agency equal to '#{identifier["agency"]}' in Collection's Layers." if field.nil?
      as_properties["#{field.code}"] = identifier["id"]
    end
    as_properties
  end

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

  def url_for_facility(id)
    url_for(:controller => 'fred_api', :action => 'show_facility',:format => :json, :id => id)
  end

  def fred_facility_format_from_ES(result)
    source = result['_source']

    obj = {}
    obj[:name] = source['name']
    obj[:uuid] = source['uuid']

    obj[:createdAt] = format_time_to_iso_string(source['created_at'])
    obj[:updatedAt] = format_time_to_iso_string(source['updated_at'])
    if source['location']
      obj[:coordinates] = [source['location']['lon'], source['location']['lat']]
    end

    # ResourceMap does not implement logical deletion yet. Thus all facilities are active.
    obj[:active] = true

    obj[:href] = url_for_facility(source['id'])

    obj[:identifiers] = source['identifiers']

    obj[:properties] = source['properties']

    obj
  end

  def format_time_to_iso_string(es_format_date_sting)
    date = Site.parse_time(es_format_date_sting).utc
    date.iso8601
  end

  def rescue_record_invalid(ex)
    if ex.record.errors[:uuid].include?("has already been taken")
      render_json({code: "409 Conflict", message: "Duplicated facility: UUID has already been taken in this collection."}, :status => 409, :layout => false)
    else
      render_json({code: "400 Record Invalid", message: "#{ex.message}"}, :status => 400, :layout => false)
    end
  end

  def rescue_runtime_error(ex)
    render_json({code: "400 Record Invalid", message: "#{ex.message}"}, :status => 400, :layout => false)
  end

  def default_rescue(ex)
    puts ex.message
    ex.backtrace.each { |bt| puts bt }
    render_json({code: "500 Internal Server Error",  message: "#{ex.message}"}, status: 500, :layout => false)
  end

  def rescue_record_not_found(ex)
    render_json({ code: "404 Not Found", message: "Resource not found" }, :status => 404, :layout => false)
  end
end
