class SiteMembershipsController < ApplicationController
  before_filter :authenticate_user!

  expose(:memberships) { [] }

  def index
    respond_to do |format|
      format.html
      format.json { render json: memberships }
    end
  end
end
