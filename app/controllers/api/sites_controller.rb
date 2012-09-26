class Api::SitesController < ApplicationController
  include Api::JsonHelper

  before_filter :authenticate_user!
  before_filter :authenticate_site_user!

  expose(:site)

  def show
    current_snapshot = site.collection.snapshot_for(current_user)
    if current_snapshot
      search = site.collection.new_search snapshot_id: current_snapshot.id, current_user_id: current_user.id
    else
      search = site.collection.new_search current_user_id: current_user.id
    end

    search.id(site.id)
    @result = search.api_results[0]

    respond_to do |format|
      format.rss
      format.json { render json: site_item_json(@result) }
    end
  end
end
