class SitesController < ApplicationController
  before_filter :authenticate_user!

  expose(:sites)
  expose(:site)

  def index
    if params[:collection_id]
      render :json => collection.root_sites.offset(params[:offset]).limit(params[:limit])
    else
      s = params[:s].to_f
      n = params[:n].to_f
      e = params[:e].to_f
      w = params[:w].to_f

      sites = collections.includes(:sites)
      sites = sites.where "sites.folder is NULL or sites.folder = 0"
      if s < n
        sites = sites.where "? <= sites.lat AND sites.lat <= ?", s, n
      else
        sites = sites.where "sites.lat >= ? OR sites.lat <= ?", s, n
      end
      if w < e
        sites = sites.where "? <= sites.lng AND sites.lng <= ?", w, e
      else
        sites = sites.where "sites.lng >= ? OR sites.lng <= ?", w, e
      end
      sites = sites.map(&:sites).flatten
      render :json => sites
    end
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
    search = Search.new params[:collection_ids]
    search.bounds = params
    render :json => search.sites
  end
end
