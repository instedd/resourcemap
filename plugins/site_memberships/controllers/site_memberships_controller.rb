class SiteMembershipsController < ApplicationController
  before_filter :authenticate_user!

  expose(:memberships) { collection.site_memberships }

  def index
    respond_to do |format|
      format.html
      format.json { render json: memberships.to_a }
    end
  end

  def set_access
    membership = memberships.find_or_create_by_field_id params[:field_id]
    membership.update_attributes Hash[params[:type], params[:access]]
    render json: :ok
  end
end
