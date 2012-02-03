class SitesController < ApplicationController
  before_filter :authenticate_user!

  expose(:sites)
  expose(:site)

  def index
    if params[:collection_id]
      render :json => collection.root_sites
    else
      sites = collections.includes(:sites).
        where("? <= sites.lat && sites.lat <= ?", params[:s].to_f, params[:n].to_f).
        where("? <= sites.lng && sites.lng <= ?", params[:w].to_f, params[:e].to_f).
        where("sites.folder is NULL or sites.folder = 0", false).
        map(&:sites).flatten
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
    render :json => site.sites.where(:parent_id => site.id)
  end
end
