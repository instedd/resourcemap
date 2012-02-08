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
    n, s, e, w = params.fetch_many(:n, :s, :e, :w).map &:to_f
    zoom = params[:z].to_i
    width, height = Clusterer.cell_size_for zoom
    bounds = {:n => n + height, :s => s - height, :e => e + width, :w => w - width}

    bounds[:n] = 90 if bounds[:n] >= 90
    bounds[:s] = -90 if bounds[:s] <= -90
    bounds[:e] = 180 if bounds[:e] >= 180
    bounds[:w] = -180 if bounds[:w] <= -180

    search = Search.new params[:collection_ids]
    search.zoom = params[:z]
    search.bounds = bounds if zoom > 2
    render :json => search.results
  end

  private

  def cluster(sites)
    clusterer = Clusterer.new params[:z]
    sites.each { |site| clusterer.add site }
    clusterer.clusters
  end
end
