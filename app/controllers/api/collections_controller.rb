class Api::CollectionsController < ApplicationController
  include Api::JsonHelper

  before_filter :authenticate_user!

  def show
    search = collection.new_search
    search.page params[:page].to_i if params[:page]
    search.in_group params[:group] if params[:group]
    search.after params[:updated_since] if params[:updated_since]
    search.full_text_search params[:search] if params[:search]
    search.sort params[:sort], params[:sort_direction] != 'desc' if params[:sort]
    search.where params.except(:action, :controller, :format, :id, :group, :page, :updated_since, :search, :sort, :sort_direction)
    @results = search.results

    respond_to do |format|
      format.rss
      format.json { render json: collection_json(collection, @results) }
    end
  rescue => ex
    render text: "#{ex.message} - Check the API documentation: https://bitbucket.org/instedd/resource_map/wiki/API", status: 400
  end
end
