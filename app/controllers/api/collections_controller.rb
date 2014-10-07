class Api::CollectionsController < ApiController
  include Api::JsonHelper
  include Api::GeoJsonHelper

  # authorize_resource :collection, :decent_exposure => true, only: [:destroy]

  before_filter :authenticate_collection_user!, :except => [:create, :show, :index]

  expose(:collection) { Collection.find(params[:collection_id] || params[:id]) }

  def index
    render json: current_user.collections.includes_count(:sites).all, each_serializer: Api::CollectionSerializer
  end

  def create
    coll_params = params[:collection]
    coll_params[:icon] ||= 'default'

    new_collection = Collection.new params[:collection]

    current_user.create_collection new_collection
    current_user.collection_count += 1
    current_user.update_successful_outcome_status
    current_user.save!
    render_json new_collection
  end

  def show
    authorize! :export, collection

    options = [:sort]

    if params[:format] == 'csv' || params[:page] == 'all'
      options << :all
      params.delete(:page)
    else
      options << :page
    end

    @results = perform_search *options

    respond_to do |format|
      format.rss { render :show, layout: false }
      format.csv { collection_csv(collection, @results) }
      format.json { render_json collection_json(collection, @results) }
    end
  end

  def sample_csv
    respond_to do |format|
      format.csv { collection_sample_csv(collection) }
    end
  end

  def collection_sample_csv(collection)
    sample_csv = collection.sample_csv current_user
    send_data sample_csv, type: 'text/csv', filename: "#{collection.name}_sites.csv"
  end

  def count
    render_json perform_search(:count).total
  end

  def histogram_by_field
    fields = collection.fields.where(code: params[:field_id])
    fields = collection.fields.where(id: params[:field_id]) if fields.empty?

    raise "Field not found" if fields.empty?

    filters = find_fields(params[:filters])

    render_json perform_histogram_search(fields.first, filters)
  end

  def geo_json
    @results = perform_search :page, :sort, :require_location
    respond_to do |format|
      format.json { render_json collection_geo_json(collection, @results) }
    end
  end

  def destroy
    collection.destroy
    head :ok
  end

  def bulk_update
    properties_to_update = params[:updates].deep_dup
    properties_to_update.delete(:properties)
    field_codes = collection.es_codes_by_field_code
    if params[:updates][:properties]
      properties_to_update[:properties] = {}
      params[:updates][:properties].each do |code, value|
        properties_to_update[:properties][field_codes[code]] = value
      end
    end
    params.delete(:updates)
    search = build_search :all
    ids = search.results.map{|s| s["_id"].to_i}
    collection.sites.where(id: ids).each do |s|
      s.validate_and_process_parameters(properties_to_update, current_user)
      s.user = current_user
      s.save
    end
    head :ok
  end

  private

  def perform_histogram_search(field, filters=nil)
    search = new_search
    search.histogram_search(field.es_code, filters)
    search.histogram_results(field.es_code)
  end

  def perform_search(*options)
    search = build_search *options
    search.api_results
  end

  def build_search(*options)
    except_params = [:action, :controller, :format, :id, :site_id, :updated_since, :search, :box, :lat, :lng, :radius, :fields, :name, :sitename, :page_size, :location_missing, :locale]

    search = new_search

    search.use_codes_instead_of_es_codes

    if options.include? :page
      search.page_size = params[:page_size].to_i if params[:page_size]
      search.page params[:page].to_i if params[:page]
      except_params << :page
    elsif options.include? :count
      search.offset 0
      search.limit 0
    elsif options.include? :all
      search.unlimited
    end

    search.id(params[:site_id]) if params[:site_id]
    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search] if params[:search]
    search.box *valid_box_coordinates if params[:box]
    search.select_fields(params[:fields]) if params[:fields]
    search.name(params[:name]) if params[:name]
    search.name_start_with(params[:sitename]) if params[:sitename]
    search.location_missing if params[:location_missing].present?

    if params[:lat] || params[:lng] || params[:radius]
      [:lat, :lng, :radius].each do |key|
        raise "Missing '#{key}' parameter" unless params[key]
        raise "Missing '#{key}' value" unless !params[key].blank?
      end
      search.radius params[:lat], params[:lng], params[:radius]
    end

    if options.include? :require_location
      search.require_location
    end

    if options.include? :sort
      search.sort params[:sort], params[:sort_direction] != 'desc' if params[:sort]
      except_params << :sort
      except_params << :sort_direction
    end

    search.where params.except(*except_params)
    search
  end

  def valid_box_coordinates
    coords = params[:box].split ','
    raise "Expected the 'box' parameter to be four comma-separated numbers" if coords.length != 4

    coords.each_with_index do |coord, i|
      Float(coord) rescue raise "Expected #{(i + 1).ordinalize} value of 'box' parameter to be a number, not '#{coord}'"
    end

    coords
  end

  def collection_csv(collection, results)
    sites_csv = collection.to_csv(results, current_user)
    send_data sites_csv, type: 'text/csv', filename: "#{collection.name}_sites.csv"
  end

  def find_fields(params)
    return nil if params.nil?
    replaced_params = {}
    params = JSON.parse(params) unless params.respond_to?(:each)
    params.each do |k,v|
      field = collection.fields.where(code: k).first
      replaced_params[field] = v
    end
    replaced_params
  end
end
