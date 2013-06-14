class Api::CollectionsController < ApplicationController
  include Api::JsonHelper
  include Api::GeoJsonHelper

  before_filter :authenticate_user!
  around_filter :rescue_with_check_api_docs

  def show
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
      format.json { render json: collection_json(collection, @results) }
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
    render json: perform_search(:count).total
  end

  def geo_json
    @results = perform_search :page, :sort, :require_location
    render json: collection_geo_json(collection, @results)
  end

  private

  def perform_search(*options)
    except_params = [:action, :controller, :format, :id, :updated_since, :search, :box, :lat, :lng, :radius]

    search = new_search

    search.use_codes_instead_of_es_codes

    if options.include? :page
      search.page params[:page].to_i if params[:page]
      except_params << :page
    elsif options.include? :count
      search.offset 0
      search.limit 0
    elsif options.include? :all
      search.unlimited
    end

    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search] if params[:search]
    search.box *valid_box_coordinates if params[:box]

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
    search.api_results
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
    sites_csv = collection.to_csv results
    send_data sites_csv, type: 'text/csv', filename: "#{collection.name}_sites.csv"
  end

  def rescue_with_check_api_docs
    yield
  rescue => ex

    Rails.logger.info ex.message
    Rails.logger.info ex.backtrace

    render text: "#{ex.message} - Check the API documentation: https://bitbucket.org/instedd/resource_map/wiki/API", status: 400
  end
end
