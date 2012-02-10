class SitesController < ApplicationController
  before_filter :authenticate_user!

  expose(:sites)
  expose(:site)

  def index
    render :json => collection.root_sites.offset(params[:offset]).limit(params[:limit])
  end

  def create
    render :json => collection.sites.create(params[:site])
  end

  def update
    site.update_attributes params[:site]
    render :json => site
  end

  def root_sites
    render :json => site.sites.where(:parent_id => site.id).offset(params[:offset]).limit(params[:limit])
  end

  def search
    zoom = params[:z].to_i

    search = Search.new params[:collection_ids]
    search.zoom = zoom
    search.bounds = params if zoom > 2
    render :json => search.results
  end
end
