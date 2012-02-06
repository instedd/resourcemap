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
    search = Search.new params[:collection_ids]
    search.bounds = params
    sites = search.sites
    if sites.length > 50
      render :json => cluster(sites)
    else
      render :json => {:sites => sites}
    end
  end

  private

  def cluster(sites)
    clusterer = Clusterer.new params[:z]
    sites.each { |site| clusterer.add site }
    clusterer.clusters
  end
end
