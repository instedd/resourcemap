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
      format.json { render_json site_item_json(@result) }
    end
  end


  def histories
    histories = site.histories.includes(:user).select('site_histories.*, users.email')
    histories = if version = params[:version]
      histories.where(version: version)
    else
      histories.order('version ASC')
    end
    respond_to do |format|
      format.json { render_json histories.map{|h| h.attributes.merge({user: h.user.try(:email)})} }
    end
  end
end
