class Api::SitesController < ApplicationController
  include Api::JsonHelper

  before_filter :authenticate_user!
  before_filter :authenticate_site_user!

  expose(:site)
  expose(:collection) { site.collection }
  expose(:current_snapshot) { collection.snapshot_for(current_user) }

  def show
    search = new_search
    search.id(site.id)
    @result = search.api_results[0]

    respond_to do |format|
      format.rss
      format.json { render json: site_item_json(@result) }
    end
  end
end
