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

    search = Search.new params[:collection_ids]
    search.bounds = {:n => n + height, :s => s - height, :e => e + width, :w => w - width} if zoom >= 2
    sites = search.sites
    sites_in_view = filter_in_view sites, n, s, e, w
    if sites_in_view.length > 10
      render :json => cluster(sites)
    else
      render :json => {:sites => sites_in_view}
    end
  end

  private

  def filter_in_view(sites, n, s, e, w)
    sites.select do |site|
      in_lat = if n > s
                 s <= site[:lat] && site[:lat] <= n
               else
                 site[:lat] <= n || site[:lat] >= s
               end
      in_lng = if e > w
                 w <= site[:lng] && site[:lng] <= e
               else
                 site[:lng] <= e || site[:lng] >= w
               end
      in_lat && in_lng
    end
  end

  def cluster(sites)
    clusterer = Clusterer.new params[:z]
    sites.each { |site| clusterer.add site }
    clusterer.clusters
  end
end
