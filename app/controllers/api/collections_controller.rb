class Api::CollectionsController < ApplicationController
  def show
    search = collection.new_search
    search.page params[:page].to_i if params[:page]
    @results = search.results
  end
end
