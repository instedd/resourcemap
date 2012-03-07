class Api::CollectionsController < ApplicationController
  before_filter :authenticate_user!

  def show
    search = collection.new_search
    search.page params[:page].to_i if params[:page]
    @results = search.results
  end
end
