class Api::CollectionsController < ApplicationController
  include Api::JsonHelper

  before_filter :authenticate_user!

  def show
    @results = perform_search :page, :sort

    respond_to do |format|
      format.rss
      format.json { render json: collection_json(collection, @results) }
    end
  rescue => ex
    render text: "#{ex.message} - Check the API documentation: https://bitbucket.org/instedd/resource_map/wiki/API", status: 400
  end

  def count
    render json: perform_search(:count).total
  end

  private

  def perform_search(*options)
    except_params = [:action, :controller, :format, :id, :group, :updated_since, :search, :box, :lat, :lng, :radius]

    search = collection.new_search

    if options.include? :page
      search.page params[:page].to_i if params[:page]
      except_params << :page
    elsif options.include? :count
      search.offset 0
      search.limit 0
    end

    search.in_group params[:group] if params[:group]
    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search] if params[:search]
    search.box *valid_box_coordinates if params[:box]

    if params[:lat] || params[:lng] || params[:radius]
      [:lat, :lng, :radius].each do |key|
        raise "Missing '#{key}' parameter" unless params[key]
      end
      search.radius params[:lat], params[:lng], params[:radius]
    end

    if options.include? :sort
      search.sort params[:sort], params[:sort_direction] != 'desc' if params[:sort]
      except_params << :sort
    end

    search.where params.except(*except_params)
    search.results
  end

  def valid_box_coordinates
    coords = params[:box].split ','
    raise "Expected the 'box' parameter to be four comma-separated numbers" if coords.length != 4

    coords.each_with_index do |coord, i|
      Float(coord) rescue raise "Expected #{(i + 1).ordinalize} value of 'box' parameter to be a number, not '#{coord}'"
    end

    coords
  end
end
