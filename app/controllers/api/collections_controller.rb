class Api::CollectionsController < ApplicationController
  before_filter :authenticate_user!

  def show
    search = collection.new_search
    search.page params[:page].to_i if params[:page]
    search.in_group params[:group] if params[:group]
    search.after params[:updated_since] if params[:updated_since]
    search.where params.except(:action, :controller, :format, :id, :group, :page, :updated_since)
    @results = search.results
  end
end
