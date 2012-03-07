class Api::SitesController < ApplicationController
  before_filter :authenticate_user!

  expose(:site)

  def show
    search = site.collection.new_search.id(site.id)
    @result = search.results[0]
  end
end
