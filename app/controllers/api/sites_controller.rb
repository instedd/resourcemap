class Api::SitesController < ApplicationController
  include Api::JsonHelper

  before_filter :authenticate_user!
  before_filter :authenticate_site_user!

  expose(:site)
  expose(:collection) { site.collection }

  def show
    search = new_search

    search.id(site.id)
    @result = search.api_results[0]

    respond_to do |format|
      format.rss
      format.json { render json: site_item_json(@result) }
    end
  end


  def histories
    if version = params[:version]
      histories = site.histories.where(version: version)
    else
      histories = site.histories.order('version ASC')
    end
    respond_to do |format|
      format.json { render json:  histories.to_json }
    end
  end
end
