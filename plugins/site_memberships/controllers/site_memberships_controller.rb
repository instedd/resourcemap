class SiteMembershipsController < ApplicationController
  before_filter :authenticate_user!

  expose(:memberships) { collection.site_memberships }

  def index
    respond_to do |format|
      format.html
      format.json { render json: memberships.to_a }
    end
  end
end
