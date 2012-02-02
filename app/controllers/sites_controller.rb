class SitesController < ApplicationController
  before_filter :authenticate_user!

  expose(:sites)
  expose(:site)

  def index
    render :json => collection.root_sites
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
